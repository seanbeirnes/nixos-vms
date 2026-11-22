# Nixpkgs overlay adding `pkgs.unstable` (nixos-unstable) and `pkgs.herdr`, both built for the host's system.
{ nixpkgs-unstable, herdrFlake }:
final: _prev:
let
  system = final.stdenv.hostPlatform.system;
in
{
  unstable = import nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };

  herdr = herdrFlake.packages.${system}.default.overrideAttrs (_: {
    cargoDeps = (final.rustPlatform.importCargoLock.override {
      # Bypass crates.io API download failures; retain Cargo.lock checksums.
      fetchurl = args: final.fetchurl (args // {
        url = builtins.replaceStrings
          [ "https://crates.io/api/v1/crates/" ]
          [ "https://static.crates.io/crates/" ]
          args.url;
      });
    }) {
      lockFile = "${herdrFlake}/Cargo.lock";
    };
  });
}
