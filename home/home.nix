{ pkgs, username, ... }: {
  imports = [
    ./programs/git.nix
    ./programs/direnv.nix
    ./programs/zoxide.nix
    ./programs/starship.nix
    ./programs/zsh.nix
    ./programs/tmux.nix
    ./programs/neovim.nix
    ./programs/ghostty.nix
    ./programs/gnome.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";
  home.sessionPath = [
    "/run/current-system/sw/bin"
    "$HOME/.nix-profile/bin"
    "/etc/profiles/per-user/${username}/bin"
  ];

  home.packages = [
    (import ./scripts/goto.nix { inherit pkgs; })
    (import ./scripts/nvim-sync.nix { inherit pkgs; })
    (import ./scripts/tnew.nix { inherit pkgs; })
  ];

  programs.home-manager.enable = true;
}
