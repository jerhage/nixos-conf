{ config, lib, ... }:
let
  cfg = config.my.greeter;
in
{
  options.my.greeter.backend = lib.mkOption {
    type = lib.types.enum [
      "none"
      "ly"
      "noctalia"
    ];
    default = "ly";
    description = ''
      Which display manager greets at login.

      - `ly`: lightweight TUI greeter, straight from nixpkgs. No extra inputs.
      - `noctalia`: graphical greeter matching the Noctalia shell, and
        `noctalia msg greeter-sync` pushes the current wallpaper and palette to
        it. Comes from the noctalia-greeter flake input, and also pulls in
        greetd, Polkit and AccountsService.
      - `none`: no display manager at all. Deliberate choice for logging in at a
        TTY and starting the compositor by hand.
    '';
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.backend != "none") {
      services.displayManager.enable = true;
    })

    (lib.mkIf (cfg.backend == "ly") {
      services.displayManager.ly.enable = true;
    })

    (lib.mkIf (cfg.backend == "noctalia") {
      services.displayManager.noctalia-greeter = {
        enable = true;
        settings = {
          cursor = {
            theme = "catppuccin-mocha-sapphire-cursors";
            size = 16;
          };
          keyboard.layout = config.services.xserver.xkb.layout;
        };
      };
    })
  ];
}
