{ config, lib, ... }:
{
  options.my.profiles.personal.enable = lib.mkEnableOption ''
    my own habits and accounts, orthogonal to the kind of machine. Not for a
    host someone else provisions
  '';

  config = lib.mkIf config.my.profiles.personal.enable {
    my.i18n.languages = lib.mkDefault [
      "korean"
      "japanese"
    ];
    my.onepassword.enable = lib.mkDefault true;
    my.shell.history = lib.mkDefault "fzf";
    my.tailscale.gui = lib.mkDefault true;
    my.devtools.languages = lib.mkDefault [
      "c"
      "deno"
      "elixir"
      "go"
      "nix"
      "node"
      "rust"
    ];
  };
}
