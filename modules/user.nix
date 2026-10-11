{ config, lib, ... }:
{
  options.my.user = lib.mkOption {
    type = lib.types.str;
    description = "Primary login user for this host";
  };

  # Deliberately no default: a host that forgets my.user fails to build.
  config.users.users.${config.my.user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
