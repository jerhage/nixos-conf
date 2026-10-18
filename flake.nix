{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Landlock sandbox for AI agents. nixpkgs lags well behind on this one.
    nono.url = "github:always-further/nono";
    nono.inputs.nixpkgs.follows = "nixpkgs";
    # TODO: drop this input once services.displayManager.noctalia-greeter
    # reaches the stable nixpkgs branch; the module is unstable-only for now.
    noctalia-greeter.url = "github:noctalia-dev/noctalia-greeter";
    noctalia-greeter.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      inherit (nixpkgs) lib;

      # Every directory under ./hosts is a host. Adding one needs no edit here.
      hostNames = builtins.attrNames (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts)
      );

      # Flake inputs reachable as plain pkgs.<name>, so a module names
      # `zen-browser` instead of inputs.zen-browser.packages.<system>.<variant>.
      overlay = final: _prev: {
        zen-browser = inputs.zen-browser.packages.${final.stdenv.hostPlatform.system}.twilight;
      };

      mkHost =
        name:
        lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = [ overlay ]; }
            ./modules
            ./hosts/${name}
            { networking.hostName = name; }
            inputs.noctalia-greeter.nixosModules.default
            inputs.nix-index-database.nixosModules.nix-index
            inputs.sops-nix.nixosModules.sops
          ];
        };

      # Systems the flake is usable from, not just the ones hosts run on, so
      # `nix fmt` and `nix run` work from the mac too.
      forAllSystems = lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forLinux = lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      nixosConfigurations = lib.genAttrs hostNames mkHost;

      # Importable by another flake: inputs.nixos-conf.nixosModules.default
      nixosModules.default = ./modules;

      # Linux only: both wrap niri or ghostty.
      packages = forLinux (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          niri-keys = pkgs.callPackage ./pkgs/niri-keys { };
          nvim-desktop-item = pkgs.callPackage ./pkgs/nvim-desktop-item { };
        }
      );

      # `nix fmt` formats every .nix file in the repo.
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      # Project scaffolding: `nix flake init -t ~/nixos-conf#devshell`
      templates = {
        devshell = {
          path = ./templates/devshell;
          description = "Plain-flake dev shell with direnv integration";
        };
        devenv = {
          path = ./templates/devenv;
          description = "devenv dev shell, for language helpers and services";
        };
      };
    };
}
