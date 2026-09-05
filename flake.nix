{
  description = "NixOS VM configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    herdr.url = "github:herdrdev/herdr/v0.8.2";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, herdr, ... }:
    let
      pkgs = nixpkgs.legacyPackages.aarch64-linux;
    in
    {
      nixosConfigurations.dev-vm = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {
          username = "devenv";
          herdrPackage = herdr.packages.aarch64-linux.default;
        };
        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/dev-vm
        ];
      };

      apps.aarch64-linux.apply-dev-vm = {
        type = "app";
        program = "${
          pkgs.writeShellApplication {
            name = "apply-dev-vm";
            runtimeInputs = with pkgs; [
              coreutils
              diffutils
              gnutar
              nixos-rebuild
            ];
            text = builtins.readFile ./bin/apply-dev-vm;
          }
        }/bin/apply-dev-vm";
      };

      formatter.aarch64-linux = pkgs.nixfmt;
    };
}
