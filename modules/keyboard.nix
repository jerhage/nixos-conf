{ config, lib, ... }:
let
  cfg = config.my.keyboard;
in
{
  options.my.keyboard.enable = lib.mkEnableOption "udev rules for ZSA keyboards (Moonlander, Voyager, Ergodox, Planck)";

  config = lib.mkIf cfg.enable {
    # Needed to flash firmware and for Oryx live training. The packaged rules
    # use TAG+="uaccess"; ZSA's own instructions use GROUP="plugdev", which does
    # not exist on NixOS, so hand-copied rules are silently discarded.
    hardware.keyboard.zsa.enable = true;
  };
}
