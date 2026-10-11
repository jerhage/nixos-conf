{ lib, ... }:
{
  # Identity options live here so a host can override them with a plain
  # assignment. Phase 1: consumed by the home-manager git module via osConfig.
  # Phase 2 (when home-manager is removed) this module also sets
  # programs.git.config, writing /etc/gitconfig.
  options.my.git = {
    userName = lib.mkOption {
      type = lib.types.str;
      default = "Jeremy Hage";
      description = "Value for git user.name";
    };
    userEmail = lib.mkOption {
      type = lib.types.str;
      default = "jhage.codingkr@gmail.com";
      description = "Value for git user.email";
    };
  };
}
