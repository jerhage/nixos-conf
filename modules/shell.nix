{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.shell;
in
{
  options.my.shell = {
    enable = lib.mkEnableOption "interactive shell tooling";

    history = lib.mkOption {
      type = lib.types.enum [
        "fzf"
        "atuin"
      ];
      default = "fzf";
      description = ''
        Which ctrl-r front-end to use.

        Both search history shared across shells. fzf reads ~/.bash_history and
        comes with the fzf setup in ~/.bashrc. atuin keeps its own store and
        records exit status, duration and directory, but replaces fzf's ctrl-r
        and up-arrow.
      '';
    };
  };

  # Aliases, functions and prompt setup live in ~/dotfiles/bash/.bashrc,
  # symlinked by my.dotfiles.links. Nix only provides the packages and the
  # system-wide bits that /etc/bashrc is responsible for.
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.bash.completion.enable = true;

        # Bash truncates history to 500 lines and overwrites the file per shell,
        # so the last shell to exit wins. Append instead, flush after every
        # command, and read in what other shells wrote.
        programs.bash.interactiveShellInit = ''
          shopt -s histappend
          HISTSIZE=100000
          HISTFILESIZE=200000
          HISTCONTROL=ignoredups
          PROMPT_COMMAND="history -a; history -n''${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
        '';

        environment.systemPackages = with pkgs; [
          starship # ~/.bashrc runs `starship init bash`
          zoxide # ~/.bashrc runs `zoxide init bash`
        ];
      }

      (lib.mkIf (cfg.history == "fzf") {
        # fzf reads an empty FZF_CTRL_R_COMMAND as "do not bind ctrl-r". Clear
        # any value inherited from a shell started while atuin was selected.
        programs.bash.interactiveShellInit = lib.mkBefore ''
          unset FZF_CTRL_R_COMMAND
        '';
      })

      (lib.mkIf (cfg.history == "atuin") {
        # atuin's hook needs bash-preexec and the module omits it; without it
        # atuin records nothing and starship stops drawing. Empty
        # FZF_CTRL_R_COMMAND makes `fzf --bash` skip binding ctrl-r. Both must
        # precede the atuin hook and ~/.bashrc's fzf init.
        programs.bash.interactiveShellInit = lib.mkBefore ''
          source ${pkgs.bash-preexec}/share/bash/bash-preexec.sh
          export FZF_CTRL_R_COMMAND=""
        '';

        programs.atuin = {
          enable = true;
          settings.update_check = false;
        };
      })
    ]
  );
}
