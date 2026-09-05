{ pkgs, herdrPackage }:
pkgs.writeShellApplication {
  name = "hnew";
  runtimeInputs = [
    herdrPackage
    pkgs.neovim
    pkgs.coreutils
    pkgs.jq
  ];
  text = ''
    set -euo pipefail

    if [[ -n "''${HERDR_ENV:-}" ]]; then
      echo "Detach from Herdr before running hnew." >&2
      exit 1
    fi

    session_name="$(basename -- "$PWD")"
    sessions="$(herdr --session "$session_name" session list --json)"

    # Include stopped sessions so their saved layout is restored, not duplicated.
    if jq -e --arg name "$session_name" 'any(.sessions[]; .name == $name)' <<< "$sessions" >/dev/null; then
      exec herdr session attach "$session_name"
    fi

    # CLI layout commands require a running server. Start without a seed workspace.
    nohup env -u HERDR_STARTUP_CWD herdr --session "$session_name" server </dev/null >/dev/null 2>&1 &
    ready=false
    for ((attempt = 0; attempt < 150; attempt++)); do
      if herdr --session "$session_name" workspace list >/dev/null 2>&1; then
        ready=true
        break
      fi
      sleep 0.1
    done
    if [[ "$ready" != true ]]; then
      echo "Herdr session '$session_name' did not become ready within 15 seconds." >&2
      exit 1
    fi

    created="$(herdr --session "$session_name" workspace create --cwd "$PWD" --label "$session_name" --focus)"
    workspace="$(jq -er '.result.workspace.workspace_id' <<< "$created")"
    tab="$(jq -er '.result.tab.tab_id' <<< "$created")"
    pane="$(jq -er '.result.root_pane.pane_id' <<< "$created")"
    herdr --session "$session_name" tab rename "$tab" nvim >/dev/null
    herdr --session "$session_name" pane run "$pane" "nvim ." >/dev/null
    herdr --session "$session_name" tab create --workspace "$workspace" --cwd "$PWD" --label shell --no-focus >/dev/null
    exec herdr session attach "$session_name"
  '';
}
