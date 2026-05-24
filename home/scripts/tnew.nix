{ pkgs }:
pkgs.writeShellApplication {
  name = "tnew";
  runtimeInputs = [
    pkgs.tmux
    pkgs.neovim
  ];
  text = ''
    set -euo pipefail

    session_name="$(basename "$PWD")"

    if tmux has-session -t "$session_name" 2>/dev/null; then
      echo "Tmux session '$session_name' already exists. Attaching..."
      tmux attach-session -t "$session_name"
      exit 0
    fi

    tmux new-session -d -s "$session_name" -c "$PWD"
    tmux new-window -t "$session_name:2" -c "$PWD"
    tmux select-window -t "$session_name:1"
    tmux send-keys -t "$session_name:1" "nvim ." C-m
    tmux attach-session -t "$session_name"
  '';
}
