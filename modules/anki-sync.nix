{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.ankiSync;
in
{
  options.my.ankiSync = {
    enable = lib.mkEnableOption "the Anki self-hosted sync server";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Loopback port to listen on.";
    };

    userFile = lib.mkOption {
      type = lib.types.path;
      default = "/run/secrets/anki-sync-users";
      description = ''
        EnvironmentFile holding the accounts, one per line as
        `SYNC_USER1=name:password`. Plain text, so it belongs in sops.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # systemd reads EnvironmentFile as root before dropping to DynamicUser.
    sops.secrets.anki-sync-users.mode = "0400";

    systemd.services.anki-sync-server = {
      description = "Anki sync server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        SYNC_HOST = "127.0.0.1";
        SYNC_PORT = toString cfg.port;
        SYNC_BASE = "/var/lib/anki-sync-server";
      };

      serviceConfig = {
        ExecStart = lib.getExe pkgs.anki-sync-server;
        EnvironmentFile = cfg.userFile;
        Restart = "on-failure";

        DynamicUser = true;
        PrivateUsers = true;
        StateDirectory = "anki-sync-server";

        # Collections are the only thing it writes; everything else is denied.
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        NoNewPrivileges = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RestrictNamespaces = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
          "~@resources"
        ];
        CapabilityBoundingSet = [ "" ];
        UMask = "0077";

        # Loopback only; Caddy is the one thing that talks to it.
        IPAddressAllow = "localhost";
        IPAddressDeny = "any";
      };
    };
  };
}
