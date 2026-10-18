{ config, lib, ... }:
let
  cfg = config.my.ssh;

  # The local host is in my.fleet too, for its key; it needs no alias to itself.
  peers = lib.filterAttrs (name: _: name != config.networking.hostName) config.my.fleet;

  # Prefer the tailnet, fall back to the LAN. Probes TCP rather than resolving,
  # because tailscaled answers MagicDNS even while the peer is unreachable.
  hostBlock =
    name: m:
    let
      tailnetName = if m.tailnet != null then m.tailnet else name;
      fallback = lib.optionalString (m.lan != null && m.tailnet != null) ''
        Match host ${name} exec "timeout 2 bash -c 'exec 3<>/dev/tcp/${tailnetName}/22' 2>/dev/null"
          HostName ${tailnetName}

      '';
    in
    fallback
    + ''
      Host ${name}
        HostName ${if m.lan != null then m.lan else tailnetName}
        User ${config.my.user}
        IdentityFile ~/.ssh/id_ed25519_nix
        IdentitiesOnly yes
        HostKeyAlias ${name}

    '';
in
{
  options.my.ssh = {
    agent.enable = lib.mkEnableOption "ssh agent for interactive sessions";
    server.enable = lib.mkEnableOption "OpenSSH server (key-only)";

    server.authorize = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "nucleus"
        "mbp"
      ];
      description = ''
        Names in `my.fleet` whose `userKey` may log in here. Explicit rather
        than role-based while the fleet is small; see `my.fleet` for the note
        on roles.
      '';
    };

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

      ''
      + lib.concatStrings (lib.mapAttrsToList hostBlock peers);

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
          X11Forwarding = lib.mkDefault false;
          AllowAgentForwarding = lib.mkDefault false;

          # A host serving localhost-bound non-HTTP services wants this on.
          # likely home server for ssh-ing into something
          AllowTcpForwarding = lib.mkDefault "no";
        };
      };

      # Public keys, so they stay in the repo rather than sops: these are read
      # at eval time, and sshd must not depend on decryption to let you in.
      users.users.${config.my.user}.openssh.authorizedKeys.keys = map (
        name: config.my.fleet.${name}.userKey
      ) cfg.server.authorize;

      assertions = map (name: {
        assertion = (config.my.fleet.${name} or null) != null && config.my.fleet.${name}.userKey != null;
        message = "my.ssh.server.authorize names ${name}, which has no userKey in my.fleet.";
      }) cfg.server.authorize;

      networking.firewall.interfaces = lib.genAttrs cfg.server.interfaces (_: {
        allowedTCPPorts = [ 22 ];
      });
    })
  ];
}
