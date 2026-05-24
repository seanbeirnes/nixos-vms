{ pkgs }:
pkgs.writeShellApplication {
  name = "goto";
  runtimeInputs = [ pkgs.fd pkgs.fzf ];
  text = ''
    set -euo pipefail

    query="''${1:-}"
    case "$query" in
      dl|downloads)
        printf '%s\n' "$HOME/Downloads"
        exit 0
        ;;
      docs)
        printf '%s\n' "$HOME/Documents"
        exit 0
        ;;
      dsktp|desk|desktop)
        printf '%s\n' "$HOME/Desktop"
        exit 0
        ;;
      repos)
        printf '%s\n' "$HOME/Desktop/repos"
        exit 0
        ;;
      cfg|config)
        printf '%s\n' "''${XDG_CONFIG_HOME:-$HOME/.config}"
        exit 0
        ;;
      home)
        printf '%s\n' "$HOME"
        exit 0
        ;;
    esac

    roots="''${GOTO_ROOTS:-$HOME/src:$HOME/work:$HOME}"

    IFS=':' read -r -a root_array <<< "$roots"

    candidates=()
    for root in "''${root_array[@]}"; do
      [ -d "$root" ] || continue
      while IFS= read -r path; do
        candidates+=("$path")
      done < <(fd --type d --max-depth 4 . "$root")
    done

    if [ "''${#candidates[@]}" -eq 0 ]; then
      echo "No directories found in GOTO_ROOTS" >&2
      exit 1
    fi

    if [ -z "$query" ]; then
      printf '%s\n' "''${candidates[@]}" | fzf
      exit 0
    fi

    printf '%s\n' "''${candidates[@]}" | fzf --filter "$query" --select-1 --exit-0
  '';
}
