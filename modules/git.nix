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

  # This writes /etc/gitconfig, so it applies to every user on the host rather
  # than just my.user. That is a deliberate exception to "configs live in the
  # dotfiles repo": git config is not managed in dotfiles, and routing it
  # through Nix is what makes the identity overridable per host, e.g.
  #   my.git.userEmail = "work@example.com";
  # in a host file. Nix cannot write into $HOME, so /etc is the only way to get
  # that override without home-manager.
  #
  # For per-project (rather than per-host) identity, prefer git's own mechanism
  # in ~/.gitconfig, which needs no rebuild:
  #   [includeIf "gitdir:~/work/"]
  #     path = ~/.config/git/config-work
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
