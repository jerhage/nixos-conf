{ config, lib, pkgs, ... }:
let cfg = config.my.shell; in
{
  options.my.shell.enable = lib.mkEnableOption "interactive shell tooling";

  # Aliases, functions and prompt setup live in ~/dotfiles/bash/.bashrc,
  # symlinked by my.dotfiles.links. Nix only provides the packages and the
  # system-wide bits that /etc/bashrc is responsible for.
  config = lib.mkIf cfg.enable {
    programs.bash.completion.enable = true;

    environment.systemPackages = with pkgs; [
      zoxide # ~/.bashrc runs `zoxide init bash`
    ];
  };
}
