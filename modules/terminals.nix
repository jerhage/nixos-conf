{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.terminals;
in
{
  options.my.terminals.enable = lib.mkEnableOption "ghostty and wezterm";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.ghostty
      pkgs.wezterm

      # Names ghostty in its Exec line, so it belongs with the terminal that
      # has to exist for it to work.
      (pkgs.callPackage ../pkgs/nvim-desktop-item { })
    ];

    # Otherwise whatever registered last wins; calibre was claiming text/plain.
    xdg.mime.defaultApplications = {
      "text/plain" = "nvim-ghostty.desktop";
      "text/markdown" = "nvim-ghostty.desktop";
      "text/csv" = "nvim-ghostty.desktop";
      "application/json" = "nvim-ghostty.desktop";
      "application/x-shellscript" = "nvim-ghostty.desktop";
    };
  };
}
