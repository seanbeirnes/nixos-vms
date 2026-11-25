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
    nvim-sync

    agents_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/agents"
    clone-or-pull https://github.com/seanbeirnes/agents "$agents_dir"

    # install.sh clones agents-private over SSH. Before `gh auth login` has set up a GitHub key, that
    # clone must fail straight away (install.sh then skips it) rather than wait on a host key or
    # passphrase prompt.
    export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=10"
    "$agents_dir/install.sh"
  '';
}
