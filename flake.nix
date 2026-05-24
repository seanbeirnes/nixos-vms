{
  description = "NixOS VM configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      pkgs = nixpkgs.legacyPackages.aarch64-linux;
    in {
      nixosConfigurations.dev-vm = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {
          username = "devenv";
        };
        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/dev-vm
        ];
      };

      apps.aarch64-linux.apply-dev-vm = {
        type = "app";
        program = "${pkgs.writeShellApplication {
          name = "apply-dev-vm";
          runtimeInputs = with pkgs; [
            coreutils
            diffutils
            gnutar
            nixos-rebuild
            sudo
          ];
          text = builtins.readFile ./bin/apply-dev-vm;
        }}/bin/apply-dev-vm";
      };

      formatter.aarch64-linux = pkgs.nixfmt;
    };
}
