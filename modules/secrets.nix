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
  options.my.secrets = {
    enable = lib.mkEnableOption "sops-nix encrypted secrets";

    file = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "../../secrets/cortex.yaml";
      description = ''
        Encrypted file this host decrypts. One file per host, so a stolen
        machine's key opens only what that machine needed.

        Null installs the sops tooling and decrypts nothing, which is what a
        host that only edits secrets wants.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.sops.secrets == { } || cfg.file != null;
        message = "my.secrets.file is unset, so the secrets modules have declared have nowhere to decrypt from.";
      }
    ];

    environment.systemPackages = with pkgs; [
      age
      sops
      ssh-to-age
    ];

    sops = {
      defaultSopsFile = lib.mkIf (cfg.file != null) cfg.file;
      defaultSopsFormat = "yaml";

      # The host decrypts with an age key derived from its ssh host key, so
      # there is no per-host key to generate or back up. Reinstalling a host
      # changes the key and the file needs re-encrypting for the new one.
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
  };
}
