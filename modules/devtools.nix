{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.my.devtools;

  languageSets = {
    bun = with pkgs; [
      bun
    ];
    c = with pkgs; [
      gcc
      gnumake
    ];
    deno = with pkgs; [
      deno
    ];
    elixir = with pkgs; [
      elixir
      elixir-ls
    ];
    go = with pkgs; [
      go
      gopls
    ];
    nix = with pkgs; [
      nixfmt
    ];
    node = with pkgs; [
      nodejs_24
      pnpm
      typescript
    ];
    python = with pkgs; [
      python3
      ruff
      uv
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

    agentSandbox = lib.mkEnableOption ''
      nono, a Landlock sandbox for AI agent harnesses. Installs the tool only;
      profiles live in ~/.config/nono/profiles and are not managed here
    '';
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.languages != [ ]) {
      environment.systemPackages = lib.concatMap (l: languageSets.${l}) cfg.languages;
    })

    (lib.mkIf cfg.agentSandbox {
      environment.systemPackages = [
        inputs.nono.packages.${pkgs.stdenv.hostPlatform.system}.prebuilt
      ];
    })

    (lib.mkIf cfg.enable {
      # Lets dynamically-linked binaries that were not built for NixOS run,
      # e.g. language-server and formatter downloads from editor plugin managers.
      programs.nix-ld.enable = true;

      # Adds the `wireshark` group and the dumpcap capability wrapper.
      programs.wireshark.enable = true;
      environment.systemPackages = [ pkgs.wireshark ];

      # Per-project dev shells, as scaffolded by the flake templates. The
      # module installs the bash hook itself, so ~/.bashrc needs no direnv line.
      # nix-direnv caches the shell so `cd` does not re-evaluate the flake.
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    })
  ];
}
