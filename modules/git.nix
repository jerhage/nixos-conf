{ config, lib, ... }:
let
  cfg = config.my.git;
in
{
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

  # Writes /etc/gitconfig, so it covers every user on the host. Git config is
  # not kept in the dotfiles repo; routing it through Nix is what makes the
  # identity overridable per host. For per-project identity use git's includeIf.
  config.programs.git = {
    enable = true;
    config = {
      user.name = cfg.userName;
      user.email = cfg.userEmail;
      init.defaultBranch = "main";
      pull.rebase = true;
      color.ui = "auto";
    };
  };
}
