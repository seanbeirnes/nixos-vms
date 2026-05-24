{ pkgs, username, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "dev-vm";
  networking.nameservers = [ "192.168.1.1" ];
  networking.networkmanager.enable = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ username ];
  };

  programs.dconf.enable = true;
  programs.zsh.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    description = "Development VM user";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.zsh;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
  };

  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  virtualisation.vmware.guest.enable = true;

  environment.systemPackages = with pkgs; [
    bat
    eza
    fd
    fzf
    ghostty
    go
    httpie
    jq
    just
    lazygit
    lua
    neovim
    nodejs
    opencode
    process-compose
    ripgrep
    tmux
    tree-sitter
    zoxide
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit username; };
    users.${username} = import ../../home/home.nix;
  };

  system.stateVersion = "25.11";
}
