{ config, lib, pkgs, ... }:
let
  cfg = config.my.devtools;

  languageSets = {
    c = with pkgs; [
      gcc
      gnumake
    ];
    go = with pkgs; [
      go
      gopls
    ];
    node = with pkgs; [
      nodejs_24
      pnpm
      typescript
    ];
    nix = with pkgs; [
      nixfmt-rfc-style
    ];
    rust = with pkgs; [
      cargo
      rustc
      rust-analyzer
    ];
  };
in
{
  options.my.devtools = {
    enable = lib.mkEnableOption "nix-ld for unpatched binaries, and wireshark capture privileges";

    languages = lib.mkOption {
      type = lib.types.listOf (lib.types.enum (builtins.attrNames languageSets));
      default = [ ];
      example = [
        "go"
        "node"
      ];
      description = ''
        Language toolchains to install. Typed as an enum of the sets defined in
        this module, so a name that does not exist fails at eval rather than
        silently installing nothing.

        Each set is meant to be complete enough to build with. `rust` includes
        rustc and rust-analyzer, not just cargo -- cargo alone cannot compile.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.languages != [ ]) {
      environment.systemPackages = lib.concatMap (l: languageSets.${l}) cfg.languages;
    })

    (lib.mkIf cfg.enable {
      # Lets dynamically-linked binaries that were not built for NixOS run,
      # e.g. language-server and formatter downloads from editor plugin managers.
      programs.nix-ld.enable = true;

      # Adds the `wireshark` group and the dumpcap capability wrapper.
      programs.wireshark.enable = true;
      environment.systemPackages = [ pkgs.wireshark ];
    })
  ];
}
