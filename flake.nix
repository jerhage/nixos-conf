{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # TODO: drop this input once services.displayManager.noctalia-greeter
    # reaches the stable nixpkgs branch; the module is unstable-only for now.
    noctalia-greeter.url = "github:noctalia-dev/noctalia-greeter";
    noctalia-greeter.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      inherit (nixpkgs) lib;

      # Every directory under ./hosts is a host. Adding one needs no edit here.
      hostNames = builtins.attrNames (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts)
      );

      mkHost =
        name:
        lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./modules
            ./hosts/${name}
            { networking.hostName = name; }
            inputs.noctalia-greeter.nixosModules.default
          ];
        };
    in
    {
      nixosConfigurations = lib.genAttrs hostNames mkHost;

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
