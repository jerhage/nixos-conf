{ config, lib, ... }:
let
  cfg = config.my.sshAgent;
in
{
  options.my.sshAgent.enable = lib.mkEnableOption "ssh agent for interactive sessions";

  config = lib.mkIf cfg.enable {
    # Replaces home-manager's services.ssh-agent. Same socket path
    # ($XDG_RUNTIME_DIR/ssh-agent), so SSH_AUTH_SOCK is unchanged.
    programs.ssh.startAgent = true;

    # Applies to every host. NixOS concatenates this BEFORE the host file's
    # extraConfig, so this "Host *" block lands above any host-specific blocks.
    # That is fine as long as the options do not overlap -- ssh takes the first
    # value it finds per option, and nothing here is also set per-host. If you
    # add an option that a host block also sets, the host block will lose:
    # check with `ssh -F <generated ssh_config> -G <alias>`.
    programs.ssh.extraConfig = ''
      Host *
        AddKeysToAgent yes
    '';

    # NixOS enables gnome's gcr-ssh-agent by default and asserts that only one
    # agent may run. It was already running alongside the home-manager agent
    # before this migration, but the plain agent is the one serving the session
    # (SSH_AUTH_SOCK=/run/user/1000/ssh-agent), so keep that and drop gcr.
    services.gnome.gcr-ssh-agent.enable = false;
  };
}
