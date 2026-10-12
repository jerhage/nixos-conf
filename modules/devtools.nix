{ config, lib, pkgs, ... }:
let cfg = config.my.devtools; in
{
  options.my.devtools.enable =
    lib.mkEnableOption "nix-ld for unpatched binaries, and wireshark capture privileges";

  config = lib.mkIf cfg.enable {
    # Lets dynamically-linked binaries that were not built for NixOS run,
    # e.g. language-server and formatter downloads from editor plugin managers.
    programs.nix-ld.enable = true;

    # Adds the `wireshark` group and the dumpcap capability wrapper.
    programs.wireshark.enable = true;
    environment.systemPackages = [ pkgs.wireshark ];
  };
}
