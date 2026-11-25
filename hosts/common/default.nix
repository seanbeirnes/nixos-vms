# Configuration shared by every dev VM, whatever the hypervisor or CPU architecture.
{ lib, pkgs, username, ... }: {
  imports = [
    ../dev-vm/hardware-configuration.nix
    ./browsers.nix
    ./t3code.nix
    ./tailscale.nix
  ]
  # local.nix is gitignored, so it's invisible when evaluating straight from the git flake.
  ++ lib.optional (builtins.pathExists ../dev-vm/local.nix) ../dev-vm/local.nix;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Each VM sets its own name in hosts/dev-vm/local.nix, so several can share a network.
  networking.hostName = lib.mkDefault "dev-vm";
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

  environment.systemPackages = with pkgs; [
    bat
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
    nodejs
    pnpm
    postgresql_18
    process-compose
    python3
    ripgrep
    tree-sitter
    uv
    vscode
  ] ++ (with pkgs.unstable; [
    bun
    claude-code
    opencode
    pi-coding-agent
  ]);

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit username; };
    users.${username} = import ../../home/home.nix;
  };

  system.stateVersion = "25.11";
}
