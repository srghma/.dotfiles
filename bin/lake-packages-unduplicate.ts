#!/usr/bin/env bun
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import { execFileSync } from "node:child_process";

type Mode = "repo_and_dir_separate_in_nix_store" | "repo_and_dir_together_in_nix_store";

const MODE: Mode = "repo_and_dir_together_in_nix_store"; // bc if separate then have warnings

// --- Terminal Colors Helper ---
const isColorSupported =
  !("NO_COLOR" in process.env) &&
  process.env.FORCE_COLOR !== "0" &&
  (Boolean(process.stdout.isTTY) || process.env.FORCE_COLOR === "1");

const c = {
  bold: (s: string | number) => (isColorSupported ? `\x1b[1m${s}\x1b[22m` : String(s)),
  dim: (s: string | number) => (isColorSupported ? `\x1b[2m${s}\x1b[22m` : String(s)),
  italic: (s: string | number) => (isColorSupported ? `\x1b[3m${s}\x1b[23m` : String(s)),
  red: (s: string | number) => (isColorSupported ? `\x1b[31m${s}\x1b[39m` : String(s)),
  green: (s: string | number) => (isColorSupported ? `\x1b[32m${s}\x1b[39m` : String(s)),
  yellow: (s: string | number) => (isColorSupported ? `\x1b[33m${s}\x1b[39m` : String(s)),
  blue: (s: string | number) => (isColorSupported ? `\x1b[34m${s}\x1b[39m` : String(s)),
  magenta: (s: string | number) => (isColorSupported ? `\x1b[35m${s}\x1b[39m` : String(s)),
  cyan: (s: string | number) => (isColorSupported ? `\x1b[36m${s}\x1b[39m` : String(s)),
  gray: (s: string | number) => (isColorSupported ? `\x1b[90m${s}\x1b[39m` : String(s)),
  brightYellow: (s: string | number) => (isColorSupported ? `\x1b[93m${s}\x1b[39m` : String(s)),
  brightGreen: (s: string | number) => (isColorSupported ? `\x1b[92m${s}\x1b[39m` : String(s)),
  brightCyan: (s: string | number) => (isColorSupported ? `\x1b[96m${s}\x1b[39m` : String(s)),
};

interface LakeManifestPackage {
  url?: string;
  type: string;
  subDir: string | null;
  scope?: string;
  rev?: string;
  name: string;
  manifestFile?: string;
  inputRev?: string;
  inherited?: boolean;
  configFile?: string;
  path?: string;
}

interface LakeManifest {
  version: string;
  packagesDir: string;
  packages: LakeManifestPackage[];
  name: string;
  lakeDir?: string;
}

interface PackageTogetherEntry {
  toolchain: string;
  name: string;
  rev: string;
  storePath: string;
  addedAt: string;
}

interface PackageSourceEntry {
  name: string;
  rev: string;
  storePath: string;
  addedAt: string;
}

interface PackageLakeEntry {
  toolchain: string;
  name: string;
  rev: string;
  storePath: string;
  addedAt: string;
}

interface StateIndex {
  version: 3;
  mode: Mode;
  together: Record<string, PackageTogetherEntry>;
  sources: Record<string, PackageSourceEntry>;
  lakes: Record<string, PackageLakeEntry>;
}

const XDG_DATA_HOME = process.env.XDG_DATA_HOME || path.join(os.homedir(), ".local", "share");
const STATE_DIR = path.join(XDG_DATA_HOME, "lake-packages-unduplicate");
const GC_ROOTS_DIR = path.join(STATE_DIR, "gcroots");
const STATE_FILE = path.join(STATE_DIR, "store.json");

function isValidLakeDirectory(lakeDir: string): boolean {
  if (!fs.existsSync(lakeDir)) return false;
  try {
    const buildPath = path.join(lakeDir, "build");
    if (fs.existsSync(buildPath) && fs.readdirSync(buildPath).length > 0) {
      return true;
    }
    const barrelPath = path.join(lakeDir, "build.barrel");
    if (fs.existsSync(barrelPath) && fs.statSync(barrelPath).size > 0) {
      return true;
    }
  } catch { }
  return false;
}

function loadState(): StateIndex {
  if (fs.existsSync(STATE_FILE)) {
    try {
      const raw = JSON.parse(fs.readFileSync(STATE_FILE, "utf-8"));
      if (raw.version === 3 && raw.together && raw.sources && raw.lakes) {
        return raw;
      }
    } catch { }
  }
  return { version: 3, mode: MODE, together: {}, sources: {}, lakes: {} };
}

function saveState(state: StateIndex): void {
  fs.mkdirSync(STATE_DIR, { recursive: true });
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2), "utf-8");
}

function cleanToolchain(toolchain: string): string {
  return toolchain.replace(/[^a-zA-Z0-9._-]/g, "_");
}

function shortToolchain(toolchain: string): string {
  const parts = toolchain.split(":");
  return parts.length > 1 ? parts[parts.length - 1] : toolchain;
}

function ensureGitSafeDirectory(): void {
  try {
    const stdout = execFileSync("git", ["config", "--global", "--get-all", "safe.directory"], {
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "ignore"],
    });
    if (stdout.includes("/nix/store/*") || stdout.includes("*")) return;
  } catch { }

  try {
    execFileSync("git", ["config", "--global", "--add", "safe.directory", "/nix/store/*"], {
      stdio: "ignore",
    });
    console.log(c.cyan("🔒 Whitelisted '/nix/store/*' in git safe.directory"));
  } catch (err: any) {
    console.warn(c.yellow(`⚠️  Could not auto-set git safe.directory: ${err.message}`));
  }
}

function nixStoreAdd(targetPath: string, gcRootName: string): string {
  try {
    const storePath = execFileSync("nix-store", ["--add", targetPath], {
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "pipe"],
    }).trim();

    try {
      fs.mkdirSync(GC_ROOTS_DIR, { recursive: true });
      const gcRootLink = path.join(GC_ROOTS_DIR, gcRootName);
      execFileSync(
        "nix-store",
        ["--realise", storePath, "--add-root", gcRootLink, "--indirect"],
        { stdio: "ignore" }
      );
    } catch { }

    return storePath;
  } catch (err: any) {
    throw new Error(`Failed to add ${targetPath} to Nix store: ${err.stderr || err.message}`);
  }
}

function isSymlink(filePath: string): boolean {
  try {
    return fs.lstatSync(filePath).isSymbolicLink();
  } catch {
    return false;
  }
}

function getSymlinkTarget(filePath: string): string | null {
  try {
    if (!fs.lstatSync(filePath).isSymbolicLink()) return null;
    return path.resolve(path.dirname(filePath), fs.readlinkSync(filePath));
  } catch {
    return null;
  }
}

function safeRemove(targetPath: string): void {
  try {
    fs.rmSync(targetPath, { recursive: true, force: true });
  } catch {
    try {
      execFileSync("chmod", ["-R", "u+w", targetPath], { stdio: "ignore" });
      fs.rmSync(targetPath, { recursive: true, force: true });
    } catch { }
  }
}

function checkManifestStale(projectDir: string): string | null {
  const tomlPath = path.join(projectDir, "lakefile.toml");
  const manifestPath = path.join(projectDir, "lake-manifest.json");

  if (!fs.existsSync(tomlPath) || !fs.existsSync(manifestPath)) return null;

  try {
    const tomlRaw = fs.readFileSync(tomlPath, "utf-8");
    const toml = tomlRaw
      .split("\n")
      .map((line) => {
        let inQuote = false;
        for (let i = 0; i < line.length; i++) {
          if (line[i] === '"' && (i === 0 || line[i - 1] !== "\\")) inQuote = !inQuote;
          if (line[i] === "#" && !inQuote) return line.slice(0, i);
        }
        return line;
      })
      .join("\n");

    const manifest: LakeManifest = JSON.parse(fs.readFileSync(manifestPath, "utf-8"));
    const manifestPackages = new Set(manifest.packages.map((p) => p.name));
    const manifestPackagesLower = new Set(manifest.packages.map((p) => p.name.toLowerCase()));

    const requiresTable = Array.from(toml.matchAll(/\[\[require\]\][\s\S]*?name\s*=\s*"([^"]+)"/g)).map((m) => m[1]);
    const requiresSection = Array.from(toml.matchAll(/\[require\.["']?([a-zA-Z0-9_-]+)["']?\]/g)).map((m) => m[1]);
    const allRequires = new Set([...requiresTable, ...requiresSection]);

    for (const req of allRequires) {
      if (!manifestPackages.has(req) && !manifestPackagesLower.has(req.toLowerCase())) {
        return `Dependency '${req}' in lakefile.toml is missing from lake-manifest.json. Run 'lake update'.`;
      }
    }
  } catch { }

  return null;
}

function isAssembledCleanly(
  pkgPath: string,
  expectedStorePath: string,
  expectedLakeStore?: string | null
): boolean {
  if (MODE === "repo_and_dir_together_in_nix_store") {
    return isSymlink(pkgPath) && getSymlinkTarget(pkgPath) === expectedStorePath;
  }

  // Separate mode checks
  if (!fs.existsSync(pkgPath) || isSymlink(pkgPath)) return false;

  const sampleFiles = ["lakefile.lean", "lakefile.toml", "README.md", "lean-toolchain"];
  let checkedSample = false;
  for (const f of sampleFiles) {
    const p = path.join(pkgPath, f);
    if (fs.existsSync(p) && isSymlink(p)) {
      const target = getSymlinkTarget(p);
      if (target && target.startsWith(expectedStorePath)) {
        checkedSample = true;
        break;
      }
    }
  }
  if (!checkedSample) return false;

  const pkgGit = path.join(pkgPath, ".git");
  if (!fs.existsSync(pkgGit) || isSymlink(pkgGit)) return false;
  if (!fs.existsSync(path.join(pkgGit, "config"))) return false;

  const lakePath = path.join(pkgPath, ".lake");
  if (expectedLakeStore) {
    if (!isSymlink(lakePath)) return false;
    const target = getSymlinkTarget(lakePath);
    if (target !== expectedLakeStore) return false;
  } else {
    if (isSymlink(lakePath)) return false;
  }

  return true;
}

function assemblePackageTogether(pkgPath: string, storePath: string): void {
  safeRemove(pkgPath);
  fs.symlinkSync(storePath, pkgPath);
}

function assemblePackageSeparate(
  pkgPath: string,
  pkg: LakeManifestPackage,
  srcStorePath: string,
  lakeStorePath: string | null
): void {
  const localLake = path.join(pkgPath, ".lake");
  const hasValidLocalLake = isValidLakeDirectory(localLake) && !isSymlink(localLake);

  let tempSavedLake: string | null = null;
  if (hasValidLocalLake && !lakeStorePath) {
    tempSavedLake = path.join(os.tmpdir(), `lake-preserve-${Date.now()}`);
    fs.renameSync(localLake, tempSavedLake);
  }

  safeRemove(pkgPath);
  fs.mkdirSync(pkgPath, { recursive: true });

  // 1. Symlink top-level files (exclude .lake and .git)
  for (const item of fs.readdirSync(srcStorePath)) {
    if (item !== ".lake" && item !== ".git") {
      fs.symlinkSync(path.join(srcStorePath, item), path.join(pkgPath, item));
    }
  }

  // 2. Setup .git bridge
  const srcGit = path.join(srcStorePath, ".git");
  if (fs.existsSync(srcGit)) {
    const pkgGit = path.join(pkgPath, ".git");
    fs.mkdirSync(pkgGit, { recursive: true });

    for (const gitItem of ["objects", "refs", "packed-refs"]) {
      const srcItem = path.join(srcGit, gitItem);
      if (fs.existsSync(srcItem)) {
        fs.symlinkSync(srcItem, path.join(pkgGit, gitItem));
      }
    }

    // HEAD MUST BE A REGULAR FILE (copied, not symlinked) for Git validate_headref
    const srcHead = path.join(srcGit, "HEAD");
    if (fs.existsSync(srcHead)) {
      fs.copyFileSync(srcHead, path.join(pkgGit, "HEAD"));
    } else if (pkg.rev) {
      fs.writeFileSync(path.join(pkgGit, "HEAD"), `${pkg.rev}\n`, "utf-8");
    }

    const srcIndex = path.join(srcGit, "index");
    if (fs.existsSync(srcIndex)) {
      fs.copyFileSync(srcIndex, path.join(pkgGit, "index"));
    }

    const remoteUrl = pkg.url || `https://github.com/leanprover-community/${pkg.name}`;
    const gitConfig = [
      "[core]",
      "\trepositoryformatversion = 0",
      "\tfilemode = true",
      "\tbare = false",
      "[remote \"origin\"]",
      `\turl = ${remoteUrl}`,
    ].join("\n") + "\n";

    fs.writeFileSync(path.join(pkgGit, "config"), gitConfig, "utf-8");
  }

  // 3. Setup .lake
  if (lakeStorePath && isValidLakeDirectory(lakeStorePath)) {
    fs.symlinkSync(lakeStorePath, path.join(pkgPath, ".lake"));
  } else if (tempSavedLake && fs.existsSync(tempSavedLake)) {
    fs.renameSync(tempSavedLake, path.join(pkgPath, ".lake"));
  }
}

function unduplicateProject(
  projectDir: string,
  state: StateIndex,
  verbose = false,
  autoBuild = false
): { added: number; linked: number; ok: number; skipped: boolean } {
  const manifestPath = path.join(projectDir, "lake-manifest.json");
  const toolchainPath = path.join(projectDir, "lean-toolchain");

  if (!fs.existsSync(manifestPath)) {
    return { added: 0, linked: 0, ok: 0, skipped: true };
  }

  const staleWarning = checkManifestStale(projectDir);
  if (staleWarning) {
    console.log(c.yellow(`  ⚠️  Warning: ${staleWarning}`));
  }

  const toolchain = fs.existsSync(toolchainPath)
    ? fs.readFileSync(toolchainPath, "utf-8").trim()
    : "unknown";

  const manifest: LakeManifest = JSON.parse(fs.readFileSync(manifestPath, "utf-8"));
  const packages = Array.isArray(manifest.packages) ? manifest.packages : [];
  const packagesDir = path.resolve(projectDir, manifest.packagesDir || ".lake/packages");

  fs.mkdirSync(packagesDir, { recursive: true });

  let added = 0;
  let linked = 0;
  let ok = 0;

  for (const pkg of packages) {
    const rawNamePadded = pkg.name.padEnd(20);

    if (!pkg.rev) {
      if (pkg.type === "path") {
        console.log(`  📂 ${c.cyan(rawNamePadded)}: ${c.dim("local path dependency (skipped)")}`);
      } else {
        console.log(`  ℹ️  ${c.gray(rawNamePadded)}: ${c.dim("dependency without git rev (skipped)")}`);
      }
      continue;
    }

    const pkgPath = path.join(packagesDir, pkg.name);
    const shortRev = pkg.rev.slice(0, 8);
    const revDisplay = c.gray(
      `rev: ${shortRev}${pkg.inputRev && pkg.inputRev !== pkg.rev ? ` @ ${c.italic(pkg.inputRev)}` : ""}`
    );
    const tcDisplay = c.magenta(`[lean: ${shortToolchain(toolchain)}]`);
    const nameStr = c.bold(rawNamePadded);

    // ==========================================
    // 1. TOGETHER MODE (Default: repo + .lake in one store path)
    // ==========================================
    if (MODE === "repo_and_dir_together_in_nix_store") {
      const togetherKey = `${toolchain}::${pkg.name}@${pkg.rev}`;
      let cachedStorePath = state.together[togetherKey]?.storePath;

      if (cachedStorePath && !fs.existsSync(cachedStorePath)) {
        delete state.together[togetherKey];
        cachedStorePath = undefined;
      }

      if (cachedStorePath) {
        if (isAssembledCleanly(pkgPath, cachedStorePath)) {
          console.log(`  ${c.brightGreen("✓")}  ${nameStr} (${revDisplay}) ${tcDisplay}: ${c.green("up-to-date")} (repo + .lake together)`);
          if (verbose) console.log(`     └─ store: ${c.gray(cachedStorePath)}`);
          ok++;
          continue;
        }

        assemblePackageTogether(pkgPath, cachedStorePath);
        console.log(`  ${c.cyan("🔗")} ${nameStr} (${revDisplay}) ${tcDisplay}: ${c.cyan("linked from cache")} (repo + .lake together)`);
        if (verbose) console.log(`     └─ store: ${c.gray(cachedStorePath)}`);
        linked++;
        continue;
      }

      // Not cached yet: verify local build exists before caching
      if (!fs.existsSync(pkgPath)) {
        console.log(`  ℹ️  ${nameStr} (${revDisplay}): ${c.dim("not present locally and not in cache")}`);
        continue;
      }

      const localLake = path.join(pkgPath, ".lake");
      let hasLocalLakeValid = isValidLakeDirectory(localLake) && !isSymlink(localLake);

      if (!hasLocalLakeValid) {
        console.log(`  ℹ️  ${nameStr} (${revDisplay}) ${tcDisplay}: ${c.yellow("no .lake build artifacts yet")} ${c.dim("(run 'lake build' first or use -b)")}`);
        continue;
      }

      if (!hasLocalLakeValid && autoBuild) {
        try {
          execFileSync("lake", ["build", pkg.name], {
            cwd: projectDir,
            stdio: verbose ? "inherit" : "ignore",
          });
          hasLocalLakeValid = isValidLakeDirectory(localLake) && !isSymlink(localLake);
        } catch { }
      }


      // Add full package (source + .git + .lake) to Nix store
      const gcRoot = `${pkg.name}-${cleanToolchain(toolchain)}-${shortRev}`;
      cachedStorePath = nixStoreAdd(pkgPath, gcRoot);

      state.together[togetherKey] = {
        toolchain,
        name: pkg.name,
        rev: pkg.rev,
        storePath: cachedStorePath,
        addedAt: new Date().toISOString(),
      };

      assemblePackageTogether(pkgPath, cachedStorePath);
      console.log(`  ${c.yellow("⏳")} ${nameStr} (${revDisplay}) ${tcDisplay}: ${c.yellow("added to Nix store & linked")} [${c.brightYellow("repo + .lake together")}]`);
      if (verbose) console.log(`     └─ store: ${c.gray(cachedStorePath)}`);
      added++;
      continue;
    }

    // ==========================================
    // 2. SEPARATE MODE (repo and .lake separate)
    // ==========================================
    const srcKey = `${pkg.name}@${pkg.rev}`;
    const lakeKey = `${toolchain}::${pkg.name}@${pkg.rev}`;

    let cachedSrcPath = state.sources[srcKey]?.storePath;
    let cachedLakePath = state.lakes[lakeKey]?.storePath;

    if (cachedSrcPath && !fs.existsSync(cachedSrcPath)) {
      delete state.sources[srcKey];
      cachedSrcPath = undefined as any;
    }
    if (cachedLakePath && !isValidLakeDirectory(cachedLakePath)) {
      delete state.lakes[lakeKey];
      cachedLakePath = undefined as any;
    }

    let srcNewlyAdded = false;
    let lakeNewlyAdded = false;

    const localLake = path.join(pkgPath, ".lake");
    const hasLocalLakeValid = isValidLakeDirectory(localLake) && !isSymlink(localLake);

    if (hasLocalLakeValid && !cachedLakePath) {
      const lakeGcRoot = `${pkg.name}-lake-${cleanToolchain(toolchain)}-${shortRev}`;
      const stagedLakePath = path.join(packagesDir, `${pkg.name}-lake`);
      fs.renameSync(localLake, stagedLakePath);
      try {
        cachedLakePath = nixStoreAdd(stagedLakePath, lakeGcRoot);
      } finally {
        if (fs.existsSync(stagedLakePath)) {
          fs.renameSync(stagedLakePath, localLake);
        }
      }

      state.lakes[lakeKey] = {
        toolchain,
        name: pkg.name,
        rev: pkg.rev,
        storePath: cachedLakePath,
        addedAt: new Date().toISOString(),
      };
      lakeNewlyAdded = true;
    }

    if (fs.existsSync(pkgPath) && !cachedSrcPath) {
      const srcGcRoot = `${pkg.name}-src-${shortRev}`;
      let stagedLakePath: string | null = null;
      if (fs.existsSync(localLake)) {
        stagedLakePath = path.join(packagesDir, `${pkg.name}-lake`);
        fs.renameSync(localLake, stagedLakePath);
      }
      try {
        cachedSrcPath = nixStoreAdd(pkgPath, srcGcRoot);
        if (stagedLakePath && isValidLakeDirectory(stagedLakePath) && !cachedLakePath) {
          const lakeGcRoot = `${pkg.name}-lake-${cleanToolchain(toolchain)}-${shortRev}`;
          cachedLakePath = nixStoreAdd(stagedLakePath, lakeGcRoot);
          state.lakes[lakeKey] = {
            toolchain,
            name: pkg.name,
            rev: pkg.rev,
            storePath: cachedLakePath,
            addedAt: new Date().toISOString(),
          };
          lakeNewlyAdded = true;
        }
      } finally {
        if (stagedLakePath && fs.existsSync(stagedLakePath)) {
          fs.renameSync(stagedLakePath, localLake);
        }
      }

      state.sources[srcKey] = {
        name: pkg.name,
        rev: pkg.rev,
        storePath: cachedSrcPath,
        addedAt: new Date().toISOString(),
      };
      srcNewlyAdded = true;
    }

    if (!cachedSrcPath) {
      console.log(`  ℹ️  ${nameStr} (${revDisplay}): ${c.dim("not present locally and not in cache")}`);
      continue;
    }

    if (!srcNewlyAdded && !lakeNewlyAdded && isAssembledCleanly(pkgPath, cachedSrcPath, cachedLakePath || null)) {
      const lakeStatus = cachedLakePath
        ? `${c.green("repo src")} + ${c.green(".lake")}`
        : `${c.green("repo src only")} ${c.dim("(no .lake)")}`;
      console.log(`  ${c.brightGreen("✓")}  ${nameStr} (${revDisplay}) ${tcDisplay}: ${c.green("up-to-date")} (${lakeStatus})`);
      if (verbose) {
        console.log(`     ${c.dim("├─ repo:")}  ${c.gray(cachedSrcPath)}`);
        if (cachedLakePath) console.log(`     └─ .lake: ${c.gray(cachedLakePath)}`);
      }
      ok++;
      continue;
    }

    assemblePackageSeparate(pkgPath, pkg, cachedSrcPath, cachedLakePath || null);

    if (srcNewlyAdded || lakeNewlyAdded) {
      const addedParts: string[] = [];
      if (srcNewlyAdded) addedParts.push(c.brightYellow("repo src added"));
      if (lakeNewlyAdded) addedParts.push(c.brightYellow(".lake build added"));

      const cachedParts: string[] = [];
      if (!srcNewlyAdded) cachedParts.push(c.cyan("repo from cache"));
      if (!lakeNewlyAdded) cachedParts.push(cachedLakePath ? c.cyan(".lake from cache") : c.dim("no .lake build"));

      const desc = [...addedParts, ...cachedParts].join(c.dim(", "));
      console.log(`  ${c.yellow("⏳")} ${nameStr} (${revDisplay}) ${tcDisplay}: ${c.yellow("added to Nix store & assembled")} [${desc}]`);
      if (verbose) {
        console.log(`     ${c.dim("├─ repo:")}  ${c.gray(cachedSrcPath)}`);
        if (cachedLakePath) console.log(`     └─ .lake: ${c.gray(cachedLakePath)}`);
      }
      added++;
    } else {
      const lakeDesc = cachedLakePath ? c.cyan(".lake cached") : c.dim("no .lake build");
      console.log(`  ${c.cyan("🔗")} ${nameStr} (${revDisplay}) ${tcDisplay}: ${c.cyan("assembled from cache")} [${c.cyan("repo cached")}, ${lakeDesc}]`);
      if (verbose) {
        console.log(`     ${c.dim("├─ repo:")}  ${c.gray(cachedSrcPath)}`);
        if (cachedLakePath) console.log(`     └─ .lake: ${c.gray(cachedLakePath)}`);
      }
      linked++;
    }
  }

  return { added, linked, ok, skipped: false };
}

function unduplicateInPwd(verbose: boolean, autoBuild: boolean): void {
  ensureGitSafeDirectory();
  const state = loadState();
  const pwd = process.cwd();

  console.log(`⚙️  ${c.bold("Mode:")} ${c.cyan(MODE)}`);
  console.log(`🔍 ${c.bold("Processing current directory:")} ${c.dim(pwd)}\n`);
  const result = unduplicateProject(pwd, state, verbose, autoBuild);
  saveState(state);

  if (!result.skipped) {
    console.log(`\n🎉 ${c.bold("Summary:")}`);
    console.log(`   Added to Nix store: ${c.bold(c.yellow(result.added))}`);
    console.log(`   Linked from cache:  ${c.bold(c.cyan(result.linked))}`);
    console.log(`   Already ok:         ${c.bold(c.green(result.ok))}`);
  }
}

function unduplicateAll(verbose: boolean, autoBuild: boolean): void {
  ensureGitSafeDirectory();
  const state = loadState();
  const projectsBase = path.join(os.homedir(), "projects");

  if (!fs.existsSync(projectsBase)) {
    console.error(c.red(`❌ Projects directory not found: ${projectsBase}`));
    process.exit(1);
  }

  console.log(`⚙️  ${c.bold("Mode:")} ${c.cyan(MODE)}`);
  console.log(`📂 ${c.bold("Scanning for Lean projects in:")} ${c.dim(projectsBase)}\n`);

  const entries = fs.readdirSync(projectsBase, { withFileTypes: true });
  let totalAdded = 0;
  let totalLinked = 0;
  let totalOk = 0;
  let projectCount = 0;

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    const projectDir = path.join(projectsBase, entry.name);
    const manifestPath = path.join(projectDir, "lake-manifest.json");

    if (!fs.existsSync(manifestPath)) continue;

    projectCount++;
    console.log(`\n${c.bold(c.brightCyan(`📦 [${projectCount}] Project: ${entry.name}`))}`);
    const res = unduplicateProject(projectDir, state, verbose, autoBuild);
    totalAdded += res.added;
    totalLinked += res.linked;
    totalOk += res.ok;
  }

  saveState(state);

  console.log(`\n${c.dim("========================================")}`);
  console.log(`🎉 ${c.bold(`Finished scanning ${projectCount} projects:`)}`);
  console.log(`   Added to Nix store: ${c.bold(c.yellow(totalAdded))}`);
  console.log(`   Linked from cache:  ${c.bold(c.cyan(totalLinked))}`);
  console.log(`   Already ok:         ${c.bold(c.green(totalOk))}`);
  console.log(`${c.dim("========================================")}`);
}

function printStatus(): void {
  const state = loadState();
  let gcRootCount = 0;
  if (fs.existsSync(GC_ROOTS_DIR)) {
    gcRootCount = fs.readdirSync(GC_ROOTS_DIR).length;
  }

  console.log(`📊 ${c.bold("Lake Unduplicate Cache Status:")}`);
  console.log(`   Active Mode:         ${c.bold(c.cyan(MODE))}`);
  console.log(`   State file:          ${c.dim(STATE_FILE)}`);
  console.log(`   GC Roots directory:  ${c.dim(GC_ROOTS_DIR)}`);
  console.log(`   Active GC roots:     ${c.bold(c.green(gcRootCount))}`);

  if (MODE === "repo_and_dir_together_in_nix_store") {
    const togetherCount = Object.keys(state.together || {}).length;
    console.log(`   Cached packages:     ${c.bold(c.cyan(togetherCount))}\n`);
  } else {
    const sourceCount = Object.keys(state.sources || {}).length;
    const lakeCount = Object.keys(state.lakes || {}).length;
    console.log(`   Cached repo sources: ${c.bold(c.cyan(sourceCount))}`);
    console.log(`   Cached .lake builds: ${c.bold(c.yellow(lakeCount))}\n`);
  }
}

function main() {
  const args = process.argv.slice(2);
  const command = args[0];
  const verbose = args.includes("--verbose") || args.includes("-v");
  const autoBuild = args.includes("--build") || args.includes("-b") || args.includes("--auto-build");

  if (!command || command === "--help" || command === "-h") {
    console.log(`${c.bold("Usage:")} lake-packages-unduplicate <command> [options]

${c.bold("Commands:")}
  ${c.cyan("unduplicate-in-pwd")}   Unduplicate packages in current working directory
  ${c.cyan("unduplicate-all")}      Scan all ~/projects/* and unduplicate
  ${c.cyan("status")}               Show cache statistics and stored entries

${c.bold("Options:")}
  ${c.dim("--verbose, -v")}        Show full Nix store paths for cached/linked packages
`);
    process.exit(0);
  }

  switch (command) {
    case "unduplicate-in-pwd":
      unduplicateInPwd(verbose, autoBuild);
      break;

    case "unduplicate-all":
      unduplicateAll(verbose, autoBuild);
      break;

    case "status":
      printStatus();
      break;

    default:
      console.error(c.red(`❌ Unknown command: ${command}`));
      process.exit(1);
  }
}

main();
