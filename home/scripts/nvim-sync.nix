# nvim-sync: clones or updates the Neovim config from seanbeirnes/vim-config.
{ pkgs }:
pkgs.writeShellApplication {
  name = "nvim-sync";
  runtimeInputs = [ (import ./clone-or-pull.nix { inherit pkgs; }) ];
  text = ''
    clone-or-pull https://github.com/seanbeirnes/vim-config "''${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
  '';
}
