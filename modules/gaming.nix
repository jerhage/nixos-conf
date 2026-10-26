{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.gaming;
in
{
  options.my.gaming = {
    enable = lib.mkEnableOption "Steam, gamemode and controller support";

    client.enable = lib.mkEnableOption ''
      Moonlight and controller udev rules, for a machine that streams *from*
      another. Independent of my.gaming.enable: a client needs no steam
    '';

    streaming = {
      enable = lib.mkEnableOption ''
        Sunshine, so Moonlight clients can stream games from this machine.
        Input goes through uinput, not the compositor, so it does not wait on
        niri's RemoteDesktop portal
      '';

      port = lib.mkOption {
        type = lib.types.port;
        default = 47989;
        description = "Sunshine's base port. The rest are offsets from it.";
      };

      # TODO: drop once niri has virtual outputs (niri-wm/niri#3800).
      prepCommands = lib.mkOption {
        type = lib.types.listOf (lib.types.attrsOf lib.types.str);
        default = [ ];
        example = [
          {
            do = "niri msg output DP-3 mode 1920x1080@60.000";
            undo = "niri msg output DP-3 mode 3440x1440@164.900";
          }
        ];
        description = ''
          Sunshine's `global_prep_cmd`: run on session start, reversed on end.
          Sunshine encodes whatever is rendered, so matching the output to the
          client's aspect is what stops a 21:9 desktop arriving letterboxed.
          Limited to the modes `niri msg outputs` lists.
        '';
      };

      interfaces = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "tailscale0" ];
        example = [ "eno1" ];
        description = ''
          Interfaces that accept Moonlight. Tailnet only by default, which
          costs a 1280 MTU and userspace encryption even on the same LAN; name
          the ethernet interface instead if that is too much.

          Moonlight's mDNS discovery does not cross the tailnet, so add the
          host by its 100.x address.
        '';
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.client.enable {
      environment.systemPackages = [ pkgs.moonlight-qt ];

      # Controller udev rules without steam or proton: moonlight reads the pad
      # locally and forwards button states.
      hardware.steam-hardware.enable = true;
    })

    (lib.mkIf cfg.enable {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;

        # Do not also put steam in systemPackages: it shadows cfg.package,
        # which carries fontPackages, with a build that has no fonts.
      };
      programs.gamemode.enable = true;

      environment.systemPackages = with pkgs; [
        lutris
        faugus-launcher
      ];

      boot.kernelModules = [
        "hid_playstation"
        "xpad"
      ];
    })

    (lib.mkIf (cfg.enable && cfg.streaming.enable) {
      services.sunshine = {
        enable = true;
        settings.port = cfg.streaming.port;

        # openFirewall writes the global lists, reaching every interface.
        openFirewall = false;

        # CAP_SYS_ADMIN, only for DRM/KMS capture. Capture goes through the
        # ScreenCast portal my.desktop provides.
        capSysAdmin = false;
      }
      // lib.optionalAttrs (cfg.streaming.prepCommands != [ ]) {
        settings.global_prep_cmd = builtins.toJSON cfg.streaming.prepCommands;
      };

      # Offsets are sunshine's, copied from the nixos module.
      networking.firewall.interfaces = lib.genAttrs cfg.streaming.interfaces (_: {
        allowedTCPPorts = map (o: cfg.streaming.port + o) [
          (-5)
          0
          1
          21
        ];
        allowedUDPPorts = map (o: cfg.streaming.port + o) [
          9
          10
          11
          13
          21
        ];
      });
    })
  ];
}
