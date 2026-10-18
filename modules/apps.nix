{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.apps;

  apps = with pkgs; [
    anki
    cryptomator
    discord
    dropbox
    gcolor3
    google-chrome
    imv
    kdePackages.kate
    obs-studio
    obsidian
    playerctl
    proton-pass
    proton-vpn
    qbittorrent
    spotify
    zen-browser
  ];
in
{
  options.my.apps = {
    enable = lib.mkEnableOption ''
      graphical applications wanted on any workstation. Not the place for a
      one-off: those belong in the host's own package list
    '';

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "zen-twilight" ];
      description = ''
        Package names to leave out on this host. Matched with `lib.getName`,
        which is not always the attribute name: zen-browser is `zen-twilight`.
        Find it with
        `nix eval --raw .#nixosConfigurations.<host>.pkgs.<attr>.name`.

        A name matching nothing is an eval error rather than a silent no-op.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.subtractLists (map lib.getName apps) cfg.exclude == [ ];
        message =
          "my.apps.exclude names nothing in the list: "
          + lib.concatStringsSep ", " (lib.subtractLists (map lib.getName apps) cfg.exclude)
          + ". Names come from lib.getName, so zen-browser is zen-twilight.";
      }
    ];

    environment.systemPackages = lib.filter (p: !(lib.elem (lib.getName p) cfg.exclude)) apps;
  };
}
