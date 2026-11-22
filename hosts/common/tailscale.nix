# Optional Tailscale for one VM, switched on with devVm.tailscale.enable in its hosts/dev-vm/local.nix.
{ config, lib, username, ... }: {
  options.devVm.tailscale.enable = lib.mkEnableOption "Tailscale on this VM, with the T3 Code server also on Tailscale HTTPS";

  config = lib.mkIf config.devVm.tailscale.enable {
    services.tailscale = {
      enable = true;
      # Without the UDP port open, peers reach the VM only through Tailscale's relays.
      openFirewall = true;
      # Lets the dev user, and so the T3 Code server, run `tailscale serve` without sudo.
      extraSetFlags = [ "--operator=${username}" ];
    };
  };
}
