{ config, lib, ... }:
let
  cfg = config.my.keyboard;
in
{
  options.my.keyboard.enable = lib.mkEnableOption "udev rules for ZSA keyboards (Moonlander, Voyager, Ergodox, Planck)";

  config = lib.mkIf cfg.enable {
    # Needed to flash firmware and to use Oryx live training in the browser.
    # The packaged rules use TAG+="uaccess", which grants the logged-in user
    # access by ACL. ZSA's own instructions use GROUP="plugdev", and there is
    # no plugdev group on NixOS, so those rules are silently discarded.
    hardware.keyboard.zsa.enable = true;
  };
}
