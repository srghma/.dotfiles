module _nix_flake {
    use ../lib/log.nu [log-info, log-header, log-err, log-done]

    const DOTFILES_LOCK = "~/.dotfiles/flake.lock"

    # Retrieves the nixpkgs revision from ~/.dotfiles/flake.lock
    def _get_dotfiles_rev [] {
        let lock_path = ($DOTFILES_LOCK | path expand)

        if not ($lock_path | path exists) {
            log-err $"❌ Error: Dotfiles lock file ($lock_path) does not exist."
            return null
        }

        let lock_data = (try { open $lock_path | from json } catch { {} })
        # '-o' (--optional) replaces deprecated '-i'
        let rev = ($lock_data | get -o nodes.nixpkgs.locked.rev)

        if ($rev | is-empty) {
            log-err $"❌ Error: Could not find 'nodes.nixpkgs.locked.rev' in ($lock_path)."
            return null
        }

        $rev
    }

    # Template for a fresh flake.nix
    def _nix_flake_template [url: string] {
        let tpl = '{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "__NIXPKGS_URL__";
  };

  outputs = inputs: {
    packages = builtins.mapAttrs (system: pkgs: {
      hello = pkgs.hello;

      default = inputs.self.packages.${system}.hello;
    }) inputs.nixpkgs.legacyPackages;
  };
}
'
        $tpl | str replace '__NIXPKGS_URL__' $url
    }

    # Initializes or syncs a flake.nix nixpkgs revision with ~/.dotfiles/flake.lock
    export def nix-flake-sync [target: path = "flake.nix"] {
        let rev = (_get_dotfiles_rev)
        if ($rev | is-empty) { return }

        let target_path = ($target | path expand)
        let nixpkgs_url = $"github:NixOS/nixpkgs/($rev)"

        log-info $"📌 Dotfiles nixpkgs rev: (ansi cyan)($rev)(ansi reset)"

        # Case 1: flake.nix does not exist -> Create from template
        if not ($target_path | path exists) {
            log-header $"🌱 ($target) not found. Creating a new flake..."
            let content = (_nix_flake_template $nixpkgs_url)

            $content | save -f $target_path
            log-done $"✔ Successfully created ($target) pinned to nixpkgs rev: ($rev)"
            return
        }

        # Case 2: flake.nix already exists -> Update nixpkgs.url
        log-header $"🔄 Updating existing ($target)..."
        let current_content = (open --raw $target_path)

        let updated_content = if ($current_content =~ 'nixpkgs\.url\s*=') {
            $current_content | str replace -r 'nixpkgs\.url\s*=\s*"[^"]*"' $"nixpkgs.url = \"($nixpkgs_url)\""
        } else if ($current_content =~ 'github:NixOS/nixpkgs') {
            $current_content | str replace -r 'github:NixOS/nixpkgs/[^"]*' $nixpkgs_url
        } else {
            log-err $"❌ Error: Could not locate a 'nixpkgs.url' or NixOS/nixpkgs input in ($target)."
            return
        }

        if $current_content == $updated_content {
            log-info $"ℹ️  ($target) is already up to date."
            return
        }

        $updated_content | save -f $target_path
        log-done $"✔ Successfully updated nixpkgs URL in ($target) to rev: ($rev)"
    }
}

use _nix_flake [nix-flake-sync]
alias nix-flake-init = nix-flake-sync
