{ config, lib, inputs, pkgs, ... }:
let
  cfg = config.my.awww;
  awww = inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.awww;
in
{
  options.my.awww.enable = lib.mkEnableOption "awww wallpaper daemon";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ awww ];

    # Replaces the home-manager services.awww module.
    # The compositor must NOT also spawn awww-daemon: a second instance cannot
    # bind the socket and crash-loops. See niri config.kdl.
    systemd.user.services.awww = {
      description = "awww-daemon";
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${awww}/bin/awww-daemon";
        Restart = "always";
        RestartSec = 10;
      };
    };
  };
}
