# Plain-flake dev shell.
#
#   nix develop     enter it
#   direnv allow    enter it automatically on cd
#
# Versions are pinned by this flake.lock, not by the system config.
{
  description = "development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { nixpkgs, ... }:
    let
      forAllSystems =
        f: nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (s: f nixpkgs.legacyPackages.${s});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          # nixpkgs only offers major versions, e.g. nodejs_22 vs nodejs_24.
          packages = with pkgs; [
            nodejs_24
            pnpm
          ];

          shellHook = ''
            # Lets tools use binaries from package.json instead of the system's,
            # e.g. nvim picking the project's oxlint over the system one.
            # Not needed for `pnpm run`/`pnpm exec`, which already do this.
            export PATH="$PWD/node_modules/.bin:$PATH"

            echo "node $(node --version)"
          '';
        };
      });
    };
}
