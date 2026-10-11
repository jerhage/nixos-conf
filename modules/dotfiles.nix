{ config, lib, ... }:
let
  cfg = config.my.dotfiles;
  home = config.users.users.${config.my.user}.home;
in
{
  options.my.dotfiles = {
    enable = lib.mkEnableOption "symlinks from $HOME into the self-managed dotfiles repo";

    path = lib.mkOption {
      type = lib.types.str;
      default = "${home}/dotfiles";
      description = "Location of the dotfiles repo.";
    };

    links = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        ".config/niri" = "niri/.config/niri";
      };
      description = ''
        Map of $HOME-relative target -> path within the dotfiles repo.

        Each entry becomes a tmpfiles `L+` rule, which replaces whatever is at
        the target (file or directory) with a symlink to the repo. Because the
        symlink points at the real file, edits take effect without a rebuild.

        This is a declarative stow: the links are recreated on every switch and
        at login. Note that removing an entry here does NOT remove the symlink
        that was already created; prune those by hand.
      '';
    };

    extraRules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "d %h/.ssh 0700 - - -" ];
      description = "Raw tmpfiles.d rules, appended after the generated links.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Applied by system.userActivationScripts.tmpfiles on every switch, and
    # again at login via systemd-tmpfiles-setup.service.
    systemd.user.tmpfiles.users.${config.my.user}.rules =
      lib.mapAttrsToList (dest: src: "L+ %h/${dest} - - - - ${cfg.path}/${src}") cfg.links
      ++ cfg.extraRules;
  };
}
