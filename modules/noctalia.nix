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

  # Noctalia is configured entirely by TOML in ~/.config/noctalia, which is
  # symlinked to the dotfiles repo by my.dotfiles.links. It watches those files
  # and hot-reloads, so config changes never need a rebuild. Nix only installs
  # the package and runs it.
  #
  # Keybinds live in the niri config and drive it over `noctalia msg`:
  #   panel-toggle launcher | bar-toggle | window-switcher
  #   session lock|logout|suspend|reboot|shutdown
  #   wallpaper-set|next|random | notification-dnd-toggle | clipboard-*
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.noctalia ];

    systemd.user.services.noctalia = {
      description = "Noctalia desktop shell";
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      # A systemd user service gets only a minimal default PATH, so the
      # launcher cannot find anything from environment.systemPackages.
      # Mirror the interactive session PATH instead.
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
