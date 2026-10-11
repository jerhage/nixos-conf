{ config, lib, ... }:
let cfg = config.my.ssh; in
{
  options.my.ssh.enable = lib.mkEnableOption "ssh agent for interactive sessions";

  config = lib.mkIf cfg.enable {
    # Replaces home-manager's services.ssh-agent. Same socket path
    # ($XDG_RUNTIME_DIR/ssh-agent), so SSH_AUTH_SOCK is unchanged.
    programs.ssh.startAgent = true;

    # NixOS enables gnome's gcr-ssh-agent by default and asserts that only one
    # agent may run. It was already running alongside the home-manager agent
    # before this migration, but the plain agent is the one serving the session
    # (SSH_AUTH_SOCK=/run/user/1000/ssh-agent), so keep that and drop gcr.
    services.gnome.gcr-ssh-agent.enable = false;
  };
}
