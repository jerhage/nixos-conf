{ config, lib, pkgs, ... }:
let cfg = config.my.cli; in
{
  options.my.cli.enable = lib.mkEnableOption "baseline command-line tooling";

  # Deliberately the set that is useful on any machine, including a headless
  # one. If something is only wanted on a desktop, it belongs in the host's
  # package list instead.
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bat
      btop
      curl
      dysk
      fastfetch
      fd
      fzf
      git
      jq
      neovim
      pv
      ripgrep
      tmux
      unzip
      wget
      yazi
      zstd
    ];
  };
}
