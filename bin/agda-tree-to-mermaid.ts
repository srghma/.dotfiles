#!/usr/bin/env bun
import { readdir, readFile } from "node:fs/promises";
import { join, extname, basename } from "node:path";

interface ModuleInfo {
  name: string;
  file: string;
  dependencies: Set<string>; // Local modules this module depends on
}

async function findAgdaFiles(dir: string): Promise<string[]> {
  const entries = await readdir(dir, { withFileTypes: true });
  const files: string[] = [];

  for (const entry of entries) {
    if (entry.isFile()) {
      const ext = extname(entry.name);
      if (ext === ".agda" || ext === ".lagda") {
        files.push(join(dir, entry.name));
      }
    }
  }

  return files;
}

function extractModuleName(filePath: string): string {
  const base = basename(filePath);
  return base.replace(/\.(agda|lagda)$/, "");
}

function parseImports(content: string, localModules: Set<string>): Set<string> {
  const dependencies = new Set<string>();

  // Regular expression to match `import ModuleName` or `open import ModuleName`
  // Handles literate Agda and regular Agda files
  const importRegex = /^\s*(?:open\s+)?import\s+([A-Za-z0-9_\.-]+)/gm;

  let match: RegExpExecArray | null;
  while ((match = importRegex.exec(content)) !== null) {
    const importedModule = match[1].trim();
    // Only include if it's a module inside this local repository
    if (localModules.has(importedModule)) {
      dependencies.add(importedModule);
    }
  }

  return dependencies;
}

async function main() {
  const projectDir = process.cwd();
  const filePaths = await findAgdaFiles(projectDir);

  // Map of module name -> file path
  const localModulesMap = new Map<string, string>();
  for (const file of filePaths) {
    const modName = extractModuleName(file);
    localModulesMap.set(modName, file);
  }

  const localModulesSet = new Set(localModulesMap.keys());
  const modules = new Map<string, ModuleInfo>();

  // Parse each file
  for (const [modName, filePath] of localModulesMap.entries()) {
    const content = await readFile(filePath, "utf-8");
    const dependencies = parseImports(content, localModulesSet);

    // Module shouldn't depend on itself
    dependencies.delete(modName);

    modules.set(modName, {
      name: modName,
      file: basename(filePath),
      dependencies,
    });
  }

  // --- 1. Compute Topological Sort / Level-based Learning Order ---
  const inDegree = new Map<string, number>();
  const graph = new Map<string, Set<string>>(); // A -> list of modules depending on A

  for (const modName of localModulesSet) {
    inDegree.set(modName, 0);
    graph.set(modName, new Set());
  }

  for (const [modName, info] of modules) {
    inDegree.set(modName, info.dependencies.size);
    for (const dep of info.dependencies) {
      graph.get(dep)!.add(modName);
    }
  }

  // Group by levels (Level 0: No local dependencies, Level 1: depends on Level 0, etc.)
  const levels: string[][] = [];
  let currentLevel = Array.from(localModulesSet).filter(
    (m) => inDegree.get(m) === 0
  );

  const remaining = new Set(localModulesSet);

  while (currentLevel.length > 0) {
    levels.push(currentLevel.sort());
    const nextLevel: string[] = [];

    for (const node of currentLevel) {
      remaining.delete(node);
      const dependents = graph.get(node) || new Set();
      for (const dep of dependents) {
        const newDegree = (inDegree.get(dep) || 0) - 1;
        inDegree.set(dep, newDegree);
        if (newDegree === 0) {
          nextLevel.push(dep);
        }
      }
    }

    currentLevel = nextLevel;
  }

  // Check for cyclic dependencies
  if (remaining.size > 0) {
    console.warn("⚠️ Warning: Circular dependency detected among modules:", Array.from(remaining));
  }

  // --- 2. Generate Mermaid Output ---
  let mermaid = "```mermaid\ngraph TD\n";
  mermaid += "    %% Node styling\n";
  mermaid += "    classDef foundational fill:#d4edda,stroke:#28a745,stroke-width:2px;\n";
  mermaid += "    classDef intermediate fill:#cce5ff,stroke:#004085,stroke-width:1px;\n";
  mermaid += "    classDef advanced fill:#fff3cd,stroke:#856404,stroke-width:1px;\n\n";

  // Add edges (dep -> module)
  for (const [modName, info] of modules) {
    for (const dep of info.dependencies) {
      mermaid += `    ${dep} --> ${modName}\n`;
    }
  }

  mermaid += "\n```\n";

  // --- 3. Output Results ---
  console.log("=================================================");
  console.log("  📚 RECOMMENDED LEARNING ORDER (Level by Level)");
  console.log("=================================================\n");

  levels.forEach((levelModules, idx) => {
    console.log(`Level ${idx + 1} (${idx === 0 ? "Foundations / Prereqs" : `Step ${idx + 1}`}):`);
    for (const mod of levelModules) {
      const info = modules.get(mod)!;
      const depsStr =
        info.dependencies.size > 0
          ? ` [depends on: ${Array.from(info.dependencies).join(", ")}]`
          : "";
      console.log(`  - ${mod} (${info.file})${depsStr}`);
    }
    console.log("");
  });

  console.log("=================================================");
  console.log("  MERMAID DEPENDENCY TREE DIAGRAM");
  console.log("=================================================\n");
  console.log(mermaid);
}

main().catch(console.error);
