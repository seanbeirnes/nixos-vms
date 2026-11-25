# sync-configs: clones or updates the user configs kept in other repos (Neovim, and coding agents from seanbeirnes/agents), then installs the agents config. Safe to rerun.
{ pkgs }:
pkgs.writeShellApplication {
  name = "sync-configs";
  runtimeInputs = [
    (import ./nvim-sync.nix { inherit pkgs; })
    (import ./clone-or-pull.nix { inherit pkgs; })
    # The agents repo's install.sh needs jq, and git and ssh to clone agents-private.
    pkgs.git
    pkgs.jq
    pkgs.openssh
  ];
  text = ''
    # Agents run this without a terminal, so git must fail rather than wait on a prompt: a host key or
    # passphrase over SSH (install.sh clones agents-private that way, which fails until `gh auth login`
    # has set up a key; install.sh then skips it), or a username over HTTPS.
    export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=10"
    export GIT_TERMINAL_PROMPT=0

    # Each step runs even if an earlier one failed, so one diverged repo doesn't block the others.
    failed=0

    nvim-sync || failed=1

    agents_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/agents"
    clone-or-pull https://github.com/seanbeirnes/agents "$agents_dir" || failed=1
    # Installs from the existing checkout even when only its update failed.
    if [ -x "$agents_dir/install.sh" ]; then
      "$agents_dir/install.sh" || failed=1
    fi

    if [ "$failed" -ne 0 ]; then
      echo "sync-configs: some steps failed (see above)." >&2
      exit 1
    fi
  '';
}
