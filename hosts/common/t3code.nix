# T3 Code server for the dev user, so T3 Code apps on other machines can pair with this VM and run its coding agents.
{ config, lib, pkgs, username, ... }:
let
  # T3 Code's default port, pinned because T3 otherwise moves to a random port when it's taken.
  port = 3773;

  t3code = pkgs.unstable.t3code.override { enableCodex = false; };

  # Whether this VM also serves T3 over Tailscale HTTPS (set per VM in local.nix).
  tailscaleServeEnabled = config.devVm.tailscale.enable;

  # Waits for tailscaled at boot, since T3 sets up Tailscale Serve only when it starts and a user
  # unit can't order itself after the system's tailscaled.service. It stops waiting once Tailscale
  # says it's logged out or stopped, and never fails the start.
  waitForTailscale = pkgs.writeShellApplication {
    name = "t3code-wait-for-tailscale";
    runtimeInputs = [
      config.services.tailscale.package
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      # At most about 80 seconds, inside systemd's default 90-second start timeout.
      for _ in $(seq 20); do
        state="$(timeout 2 tailscale status --json 2>/dev/null | jq -r '.BackendState // empty' || true)"
        case "$state" in
          Running) exit 0 ;;
          NeedsLogin | NeedsMachineAuth | Stopped) break ;;
        esac
        sleep 2
      done
      echo "Tailscale isn't up (state: ''${state:-no answer}); starting without Tailscale HTTPS." >&2
      echo "After 'sudo tailscale up', run 'systemctl --user restart t3code'." >&2
    '';
  };
in
{
  # For `t3 pair`, `t3 policy show`, and the other t3 commands.
  environment.systemPackages = [ t3code ];

  # Managed policy read by every T3 Code process on the VM. Only a locked telemetry opt-out, so
  # providers and settings stay the user's choice.
  environment.etc."t3code/policy.json".text = builtins.toJSON {
    schemaVersion = 1;
    organization = "nixos-vms";
    limits.telemetry = false;
  };

  networking.firewall.allowedTCPPorts = [ port ];

  # Starts the dev user's systemd instance at boot, so the server runs without a desktop login.
  users.users.${username}.linger = true;

  # A NixOS user unit rather than a Home Manager one, because switch-to-configuration honors
  # restartIfChanged for it.
  systemd.user.services.t3code = {
    description = "T3 Code server";
    wantedBy = [ "default.target" ];
    # Units in /etc/systemd/user load for every user, including GDM's greeter.
    unitConfig.ConditionUser = username;
    # Restarting the server ends every T3 terminal and agent turn, including one running this switch.
    restartIfChanged = false;
    # Gives up after 5 quick failures, such as the port being taken, instead of retrying forever. The
    # window is longer with Tailscale, since each start can spend up to 80 seconds waiting for it.
    startLimitIntervalSec = if tailscaleServeEnabled then 900 else 300;
    startLimitBurst = 5;

    # The default service PATH has only coreutils, grep, sed and systemd. Agents (claude, opencode, pi),
    # git and gh come from the same profiles as in a login shell. T3 also prepends the PATH it reads
    # from the user's login shell, which adds Home Manager's session paths.
    enableDefaultPath = false;
    environment = {
      PATH = lib.concatStringsSep ":" [
        "/run/wrappers/bin"
        "/etc/profiles/per-user/${username}/bin"
        "/nix/var/nix/profiles/default/bin"
        "/run/current-system/sw/bin"
      ];
      T3CODE_TELEMETRY_ENABLED = "false";
      OTEL_SDK_DISABLED = "true";
    };

    serviceConfig = {
      Type = "simple";
      WorkingDirectory = "%h";
      ExecStartPre = lib.mkIf tailscaleServeEnabled (lib.getExe waitForTailscale);
      ExecStart = lib.concatStringsSep " " (
        [
          "${t3code}/bin/t3"
          "serve"
          "--port"
          (toString port)
          "--lan"
        ]
        ++ lib.optional tailscaleServeEnabled "--tailscale-serve"
      );
      Restart = "always";
      RestartSec = 5;
      # As in T3's own unit: SIGTERM goes to the server alone so it can stop its helpers in order, and
      # a helper killed for using too much memory doesn't stop the server.
      KillMode = "mixed";
      OOMPolicy = "continue";
    };
  };
}
