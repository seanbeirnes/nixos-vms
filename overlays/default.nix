# Nixpkgs overlay adding `pkgs.unstable` (nixos-unstable), built for the host's system.
{ nixpkgs-unstable }:
final: _prev: {
  unstable = import nixpkgs-unstable {
    inherit (final.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
}
