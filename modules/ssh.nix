{ config, lib, ... }:
let
  cfg = config.my.ssh;
in
{
  options.my.ssh = {
    agent.enable = lib.mkEnableOption "ssh agent for interactive sessions";
    server.enable = lib.mkEnableOption "OpenSSH server (key-only)";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.agent.enable {
      programs.ssh.startAgent = true;

      # NixOS puts this before the host's own extraConfig, and ssh takes the
      # first value it finds per option, so a host block loses on any option
      # also set here. Check with `ssh -G <alias>`.
      programs.ssh.extraConfig = ''
        Host *
          AddKeysToAgent yes
      '';

      # NixOS enables gnome's gcr-ssh-agent and asserts only one agent may
      # run; programs.ssh.startAgent is the one serving the session.
      services.gnome.gcr-ssh-agent.enable = false;
    })

    (lib.mkIf cfg.server.enable {
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
    })
  ];
}
