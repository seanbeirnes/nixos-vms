{ ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ls = "eza";
      ll = "ls -lah";
      lg = "lazygit";
      v = "nvim";
      ta = "tmux attach -t main || tmux new -s main";
    };

    initContent = ''
      g() {
        local target
        target="$(goto "$@")" || return
        if [ -n "$target" ] && [ -d "$target" ]; then
          cd "$target"
        fi
      }
    '';
  };
}
