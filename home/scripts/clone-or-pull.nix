# clone-or-pull: clones a git repository into a directory, or fast-forwards it if it's already a clone.
{ pkgs }:
pkgs.writeShellApplication {
  name = "clone-or-pull";
  runtimeInputs = [ pkgs.git ];
  text = ''
    if [ "$#" -ne 2 ]; then
      echo "usage: clone-or-pull <repo-url> <directory>" >&2
      exit 64
    fi

    repo_url="$1"
    target_dir="$2"

    if [ -d "$target_dir/.git" ]; then
      echo "Updating $target_dir"
      git -C "$target_dir" pull --ff-only
      exit 0
    fi

    # git clone accepts an existing empty directory, so nothing ever has to be deleted.
    if [ -e "$target_dir" ] || [ -L "$target_dir" ]; then
      if [ ! -d "$target_dir" ] || [ -n "$(ls -A "$target_dir")" ]; then
        echo "Refusing to overwrite $target_dir: it exists and isn't an empty directory or a git clone." >&2
        echo "Move it aside, then run this again." >&2
        exit 1
      fi
    fi

    mkdir -p "$(dirname "$target_dir")"
    echo "Cloning $repo_url into $target_dir"
    git clone "$repo_url" "$target_dir"
  '';
}
