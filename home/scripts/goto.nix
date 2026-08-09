{ pkgs }:
let
  inherit (pkgs.lib) concatMapStringsSep concatStringsSep escapeShellArg;

  shortcuts = [
    {
      names = [
        "dl"
        "downloads"
      ];
      destination = "$HOME/Downloads";
      description = "Downloads directory";
    }
    {
      names = [ "docs" ];
      destination = "$HOME/Documents";
      description = "Documents directory";
    }
    {
      names = [
        "dsktp"
        "desk"
        "desktop"
      ];
      destination = "$HOME/Desktop";
      description = "Desktop directory";
    }
    {
      names = [ "repos" ];
      destination = "$HOME/Desktop/repos";
      description = "Repositories directory";
    }
    {
      names = [
        "cfg"
        "config"
      ];
      destination = "\${XDG_CONFIG_HOME:-$HOME/.config}";
      description = "Configuration directory";
    }
    {
      names = [ "home" ];
      destination = "$HOME";
      description = "Home directory";
    }
  ];

  shortcutCases = concatMapStringsSep "\n" (shortcut: ''
    ${concatStringsSep "|" shortcut.names})
      base="${shortcut.destination}"
      ;;
  '') shortcuts;

  shortcutUsage = concatMapStringsSep "\n" (shortcut: ''
    printf '  %-24s %-28s %s\n' \
      ${escapeShellArg (concatStringsSep ", " shortcut.names)} \
      "${shortcut.destination}" \
      ${escapeShellArg shortcut.description}
  '') shortcuts;
in
pkgs.writeShellApplication {
  name = "goto";
  text = ''
        set -euo pipefail

        usage() {
          {
            printf 'Usage: g <shortcut[/path]>\n'
            printf '       g <directory>\n\n'
            printf 'Shortcuts:\n'
    ${shortcutUsage}
          } >&2
        }

        if [ "$#" -eq 0 ]; then
          usage
          exit 0
        fi

        if [ "$#" -ne 1 ]; then
          printf 'goto: expected one path argument\n\n' >&2
          usage
          exit 2
        fi

        query="$1"
        case "$query" in
          -h|--help|help)
            usage
            exit 0
            ;;
        esac

        shortcut="''${query%%/*}"
        base=""
        case "$shortcut" in
    ${shortcutCases}
        esac

        if [ -n "$base" ]; then
          if [[ "$query" == */* ]]; then
            target="$base/''${query#*/}"
          else
            target="$base"
          fi
        elif [ -d "$query" ]; then
          target="$query"
        else
          printf "goto: unknown shortcut or directory: %s\n\n" "$query" >&2
          usage
          exit 1
        fi

        if [ ! -d "$target" ]; then
          printf "goto: directory does not exist: %s\n" "$target" >&2
          exit 1
        fi

        printf '%s\n' "$target"
  '';
}
