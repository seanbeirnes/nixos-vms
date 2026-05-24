{ pkgs }:
pkgs.writeShellApplication {
  name = "nvim-sync";
  runtimeInputs = [ pkgs.git ];
  text = ''
    set -euo pipefail

    target_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
    repo_url="https://github.com/seanbeirnes/vim-config"

    if [ -d "$target_dir/.git" ]; then
      echo "Syncing Neovim config at: $target_dir"
      git -C "$target_dir" pull --ff-only
      exit 0
    fi

    if [ -d "$target_dir" ] && [ -n "$(ls -A "$target_dir")" ]; then
      echo "Refusing to overwrite non-empty directory: $target_dir" >&2
      echo "Move it aside, then run nvim-sync again." >&2
      exit 1
    fi

    mkdir -p "$(dirname "$target_dir")"
    rm -rf "$target_dir"

    echo "Cloning $repo_url into $target_dir"
    git clone "$repo_url" "$target_dir"
    echo "Neovim config synced successfully."
  '';
}
