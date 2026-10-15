{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.secrets;
in
{
  options.my.secrets.enable = lib.mkEnableOption "sops-nix encrypted secrets";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      age
      sops
      ssh-to-age
    ];

    sops = {
      defaultSopsFile = ../secrets/secrets.yaml;
      defaultSopsFormat = "yaml";

      # The host decrypts with an age key derived from its ssh host key, so
      # there is no per-host key to generate or back up. Reinstalling a host
      # changes the key and the file needs re-encrypting for the new one.
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

      # Proves the pipeline end to end. Decrypts to /run/secrets/test, which
      # is tmpfs and root-only. Delete once a real secret replaces it.
      secrets.test = {
        mode = "0400";
        owner = "root";
      };
    };
  };
}
