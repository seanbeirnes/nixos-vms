{ pkgs, username, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "dev-vm";
  networking.nameservers = [ "192.168.1.1" ];
  networking.networkmanager = {
    enable = true;
    insertNameservers = [ "192.168.1.1" ];
  };
  networking.firewall.allowedTCPPorts = [ 8080 ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ username ];
  };

  nixpkgs.config.allowUnfree = true;

  programs.dconf.enable = true;
  programs.nix-ld.enable = true;
  programs.zsh.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    description = "Development VM user";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
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

  virtualisation.docker = {
    enable = true;
    package = pkgs.docker_29;
  };
  virtualisation.vmware.guest.enable = true;

  environment.systemPackages = with pkgs; [
    bat
    bun
    chromium
    eza
    fd
    firefox
    fzf
    gcc
    gh
    ghostty
    go
    gnumake
    httpie
    jq
    just
    lazygit
    lua
    neovim
    nodejs
    opencode
    pnpm
    postgresql_18
    process-compose
    python3
    ripgrep
    tmux
    tree-sitter
    uv
    vscode
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
