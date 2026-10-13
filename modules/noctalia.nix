{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.noctalia;
in
{
  options.my.noctalia.enable = lib.mkEnableOption "Noctalia desktop shell";

  # Configured by TOML in ~/.config/noctalia, symlinked to the dotfiles repo and
  # hot-reloaded, so config changes need no rebuild. Nix installs and runs it.
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.noctalia ];

    systemd.user.services.noctalia = {
      description = "Noctalia desktop shell";
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      # A user service gets a minimal PATH, so the launcher finds nothing from
      # environment.systemPackages. Mirror the interactive session PATH.
      path = [
        "/run/wrappers"
        "/etc/profiles/per-user/${config.my.user}"
        "/nix/var/nix/profiles/default"
        "/run/current-system/sw"
      ];

      serviceConfig = {
        # Foreground: the -d/--daemon flag would detach and hide it from systemd.
        ExecStart = "${pkgs.noctalia}/bin/noctalia";
        ExecReload = "${pkgs.noctalia}/bin/noctalia msg config-reload";
        Restart = "on-failure";
        RestartSec = 3;
      };
    };

    assertions = [
      {
        assertion = cfg.enable -> config.my.niri.enable;
        message = "my.noctalia needs a Wayland session; enable my.niri on this host.";
      }
    ];
  };
}
