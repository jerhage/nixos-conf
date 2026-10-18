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
      type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
      default = { };
      example = {
        ".config/niri" = "niri/.config/niri";
      };
      description = ''
        Map of $HOME-relative target -> path within the dotfiles repo.

        Declared by the module that owns the program, so enabling the module
        brings its config with it. Hosts add entries for anything no module
        owns.

        Set an entry to null to take a path back from the module that declared
        it, which is the only way to opt out: the module system cannot remove
        an attribute. Leaves the path alone rather than linking it, so a hand
        written config survives a switch.

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
    # I'm declaring these here here instead of in each feature module, so the modules themselves remain pure.
    # This means anyone else can target the modules and use them without my personal configuration breaking it.
    # For example, niri.nix is importable on its own and anyone can use their own config setup.
    my.dotfiles.links = lib.mkMerge [
      (lib.mkIf config.my.shell.enable {
        ".bashrc" = "bash/.bashrc";
        ".profile" = "bash/.profile";
        ".config/starship" = "starship/.config/starship";
        ".config/starship.toml" = "starship/.config/starship.toml";
      })

      (lib.mkIf config.my.cli.enable {
        ".config/nvim" = "nvim/.config/nvim";
        ".config/tmux" = "tmux/.config/tmux";
        ".config/yazi" = "yazi/.config/yazi";
      })

      (lib.mkIf config.my.niri.enable { ".config/niri" = "niri/.config/niri"; })

      (lib.mkIf config.my.noctalia.enable {
        ".config/noctalia" = "noctalia/.config/noctalia";
        # Noctalia writes GUI and msg changes here, and this file loads after
        # ~/.config/noctalia, so it wins. Linked so styling is tracked.
        ".local/state/noctalia/settings.toml" = "noctalia/.local/state/noctalia/settings.toml";
      })

      (lib.mkIf config.my.theming.enable {
        ".config/gtk-3.0/settings.ini" = "gtk/.config/gtk-3.0/settings.ini";
        ".config/gtk-4.0/settings.ini" = "gtk/.config/gtk-4.0/settings.ini";
        ".gtkrc-2.0" = "gtk/.gtkrc-2.0";
      })

      (lib.mkIf config.my.mpv.enable { ".config/mpv/mpv.conf" = "mpv/.config/mpv/mpv.conf"; })

      # Individual files, not the directory: conf/cached_layouts is a
      # regenerated cache, and fcitx5 writes these on GUI changes.
      (lib.mkIf config.my.i18n.inputMethod.enable {
        ".config/fcitx5/profile" = "fcitx5/.config/fcitx5/profile";
        ".config/fcitx5/config" = "fcitx5/.config/fcitx5/config";
        ".config/fcitx5/conf/hangul.conf" = "fcitx5/.config/fcitx5/conf/hangul.conf";
        ".config/fcitx5/conf/keyboard.conf" = "fcitx5/.config/fcitx5/conf/keyboard.conf";
        ".config/fcitx5/conf/notifications.conf" = "fcitx5/.config/fcitx5/conf/notifications.conf";
      })

      (lib.mkIf config.my.devtools.agentSandbox {
        ".config/nono/profiles" = "nono/.config/nono/profiles";
      })

      (lib.mkIf config.my.terminals.enable {
        ".config/ghostty" = "ghostty/.config/ghostty";
        ".config/wezterm" = "wezterm/.config/wezterm";
      })
    ];

    # Applied by system.userActivationScripts.tmpfiles on every switch, and
    # again at login via systemd-tmpfiles-setup.service.
    systemd.user.tmpfiles.users.${config.my.user}.rules =
      lib.mapAttrsToList (dest: src: "L+ %h/${dest} - - - - ${cfg.path}/${src}") (
        lib.filterAttrs (_: src: src != null) cfg.links
      )
      ++ cfg.extraRules;
  };
}
