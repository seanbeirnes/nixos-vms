{ pkgs, username, herdrPackage, ... }: {
  imports = [
    ./programs/git.nix
    ./programs/direnv.nix
    ./programs/zoxide.nix
    ./programs/starship.nix
    ./programs/zsh.nix
    ./programs/herdr.nix
    ./programs/neovim.nix
    ./programs/ghostty.nix
    ./programs/gnome.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";
  home.sessionVariables.PNPM_HOME = "/home/${username}/.local/share/pnpm";
  home.sessionPath = [
    "/run/current-system/sw/bin"
    "$HOME/.nix-profile/bin"
    "/etc/profiles/per-user/${username}/bin"
    "$HOME/.railway/bin"
    "/home/${username}/.local/share/pnpm"
  ];

  home.packages = [
    (import ./scripts/goto.nix { inherit pkgs; })
    (import ./scripts/nvim-sync.nix { inherit pkgs; })
    (import ./scripts/hnew.nix { inherit pkgs herdrPackage; })
    (pkgs.writeShellApplication {
      name = "pbcopy";
      runtimeInputs = [ pkgs.wl-clipboard ];
      text = ''
        wl-copy "$@"
      '';
    })
    (pkgs.writeShellApplication {
      name = "pbpaste";
      runtimeInputs = [ pkgs.wl-clipboard ];
      text = ''
        wl-paste "$@"
      '';
    })
  ];

  programs.home-manager.enable = true;
}
