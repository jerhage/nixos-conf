{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.cli;
in
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
      dnsutils # dig
      dysk
      fastfetch
      fd
      file
      fzf
      git
      jq
      lsof
      neovim
      p7zip # 7z, reads rar
      pv
      ripgrep
      tmux
      tree
      unzip
      wget
      yazi
      zip
      zstd
    ];

    # .bashrc only covers interactive shells; this reaches GUI apps and units.
    environment.variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };
}
