{ config, lib, ... }:
let
  cfg = config.my.ssh;
in
{
  options.my.ssh = {
    agent.enable = lib.mkEnableOption "ssh agent for interactive sessions";
    server.enable = lib.mkEnableOption "OpenSSH server (key-only)";

    server.interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "tailscale0" ];
      example = [
        "eno1"
        "tailscale0"
      ];
      description = ''
        Interfaces that accept SSH. Port 22 is opened per interface rather than
        globally, so a new bridge, VM or wifi link does not expose it by default.
      '';
    };
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

        # Defaults to true, which opens port 22 on every interface.
        openFirewall = false;

        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
          PubkeyAuthentication = true;
          AllowUsers = [ config.my.user ];

          # Optional hardening
          # AllowTcpForwarding = "no";
          # X11Forwarding = false;
          # AllowAgentForwarding = false;
        };
      };

      networking.firewall.interfaces = lib.genAttrs cfg.server.interfaces (_: {
        allowedTCPPorts = [ 22 ];
      });
    })
  ];
}
