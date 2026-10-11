{ osConfig, ... }:

{
  programs.git = {
    enable = true;
    settings = {

      user.name = osConfig.my.git.userName;
      user.email = osConfig.my.git.userEmail;
      init.defaultBranch = "main";
      pull.rebase = true;
      color.ui = "auto";
    };
  };
}
