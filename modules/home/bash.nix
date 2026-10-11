{ config, pkgs, ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      grep = "grep --color=auto";
      ll = "ls -l";
      la = "ls -lAtr";
      cat = "bat";
      ta = "tmux a";

      nr = "nixos-rebuild switch --flake ~/nixos-conf --sudo";
      # nn = "nvim +':cd ~/nixos-conf/'";
      nn = "(cd ~/nixos-conf/ && nvim)";
      nfu = "nix flake update";
      ngc = "nix store gc";
      nf = "nvim ~/nixos-conf/flake.nix";
      # nw = "nvim ~/dotfiles/wezterm/.config/wezterm/wezterm.lua";
      # nc = "nvim +':cd ~/dotfiles/nvim/.config/nvim/'";
      nc = "(cd ~/dotfiles/nvim/.config/nvim/ && nvim)";
      wr = "$HOME/dotfiles/scripts/.local/awww/awww_randomize.sh";
      ss = "source ~/.bashrc";
    };

    # Your environment variables
    initExtra = ''

      compress() { 
          local dir="''${1%/}"
          local size
          size=$(du -sb "$dir" | awk '{print $1}')

          tar -cf - "$dir" | pv -s "$size" | zstd -T0 - > "''${dir}.tar.zst"
      }
      decompress() {
          local archive="$1"
          local size
          size=$(stat -c%s "$archive")

          pv -s "$size" "$archive" | zstd -d - | tar -xf -
      }

        export KIME_CONFIG="$HOME/.config/kime/config.yaml"
        export PATH="$HOME/.local/bin:$PATH"
        export GOPATH=$HOME/go
        export PATH="$PATH:$HOME/go/bin"

        export EDITOR=nvim
          # Uncomment the following line if you don't like systemctl's auto-paging feature:
          # export SYSTEMD_PAGER=

          # User specific aliases and functions
          if [ -d ~/.bashrc.d ]; then
              for rc in ~/.bashrc.d/*; do
                  if [ -f "$rc" ]; then
                      . "$rc"
                  fi
              done
          fi
          unset rc

          #
          # --- setup fzf theme ---
          fg="#CBE0F0"
          bg="#011628"
          bg_highlight="#143652"
          purple="#B388FF"
          blue="#06BCE4"
          cyan="#2CF9ED"

          show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"
          export FZF_DEFAULT_OPTS="--color=fg:$fg,bg:$bg,hl:$purple,fg+:$fg,bg+:$bg_highlight,hl+:$purple,info:$blue,prompt:$cyan,pointer:$cyan,marker:$cyan,spinner:$cyan,header:$cyan"
          export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
          export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
          # -- Use fd instead of find --
          export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
          export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
          export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

          # Use fd (https://github.com/sharkdp/fd) for listing path candidates.
          # - The first argument to the function ($1) is the base path to start traversal
          # - See the source code (completion.{bash,zsh}) for the details.
          _fzf_compgen_path() {
              fd --hidden --exclude .git . "$1"
          }

          # Use fd to generate the list for directory completion
          _fzf_compgen_dir() {
              fd --type=d --hidden --exclude .git . "$1"
          }

          # Advanced customization of fzf options via _fzf_comprun function
          # - The first argument to the function is the name of the command.
          # - You should make sure to pass the rest of the arguments to fzf.
          _fzf_comprun() {
              local command=$1
              shift

              case "$command" in
              cd) fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
              export | unset) fzf --preview "eval 'echo $'{}" "$@" ;;
              ssh) fzf --preview 'dig {}' "$@" ;;
              *) fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
              esac
          }
        eval "$(starship init bash)"
        eval "$(fzf --bash)"
        # eval "fastfetch"
    '';

  };

}
