{ config, lib, ... }:
let
  cfg = config.my.sshServer;
in
{
  options.my.sshServer.enable = lib.mkEnableOption "OpenSSH server (key-only)";

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;

      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        PubkeyAuthentication = true;

        # Optional hardening
        # AllowTcpForwarding = "no";
        # X11Forwarding = false;
        # AllowAgentForwarding = false;
      };
    };

    networking.firewall.allowedTCPPorts = [ 22 ];
  };
}
