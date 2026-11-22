{
  description = "NixOS VM configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Fast-moving tools (coding agents, Bun, Herdr) release faster than the stable channel updates.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      # Builds a per-system attribute set for every VM architecture, passing each system's pkgs to f.
      forEachSystem =
        f:
        nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ] (
          system: f nixpkgs.legacyPackages.${system}
        );

      # Builds a dev VM for one hypervisor. The CPU architecture comes from the VM's
      # hardware-configuration.nix (nixpkgs.hostPlatform), so it isn't set here.
      mkHost =
        hypervisorModule:
        nixpkgs.lib.nixosSystem {
          specialArgs.username = "devenv";
          modules = [
            home-manager.nixosModules.home-manager
            {
              nixpkgs.overlays = [
                (import ./overlays { inherit nixpkgs-unstable; })
              ];
            }
            ./hosts/common
            hypervisorModule
          ];
        };

      vmware = mkHost ./hosts/vmware;
    in
    {
      nixosConfigurations = {
        dev-vm-vmware = vmware;
        dev-vm-proxmox = mkHost ./hosts/proxmox;
        # Kept so commands written for the original VMware-only config keep working.
        dev-vm = vmware;
      };

      apps = forEachSystem (pkgs: {
        apply-dev-vm = {
          type = "app";
          program = "${
            pkgs.writeShellApplication {
              name = "apply-dev-vm";
              runtimeInputs = with pkgs; [
                coreutils
                diffutils
                gnugrep
                gnutar
                nixos-rebuild
                systemd
              ];
              text = builtins.readFile ./bin/apply-dev-vm;
            }
          }/bin/apply-dev-vm";
        };
      });

      formatter = forEachSystem (pkgs: pkgs.nixfmt);
    };
}
