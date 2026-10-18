{
  config,
  lib,
  inputs,
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
      # Mason's prebuilt is a generic Linux .NET binary and cannot find libicu.
      marksman
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

    # Which package provides a command, without running it.
    environment.shellAliases.whichpkg = ", -p";

    programs.nix-index-database = {
      enable = true;
      comma.enable = true;
    };

    # The default index is 102 MB and covers every file. The small one indexes
    # only bin/, which is all comma and command-not-found look at.
    programs.nix-index.package =
      inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}.nix-index-with-small-db;

    # .bashrc only covers interactive shells; this reaches GUI apps and units.
    environment.variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    # Without the terminal's terminfo, any pager fails over ssh: `systemctl
    # status` from ghostty dies with "'xterm-ghostty': unknown terminal type".
    environment.enableAllTerminfo = true;
  };
}
