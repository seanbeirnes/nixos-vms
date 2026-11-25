# NixOS VMs

Standalone NixOS VM configurations for VMware Fusion on Apple Silicon Macs and for Proxmox on x86_64 (AMD or Intel) servers.

This repo is intended for disposable or semi-disposable development VMs where the VM provides the sandbox boundary and NixOS provides a reproducible operating-system configuration.

## Overview

The flake has one host configuration per hypervisor. Both share the same system and user configuration:

| Configuration | Hypervisor | Architecture |
| --- | --- | --- |
| `dev-vm-vmware` | VMware Fusion on Apple Silicon | `aarch64-linux` |
| `dev-vm-proxmox` | Proxmox (QEMU/KVM) | `x86_64-linux` |

`dev-vm` is kept as an alias of `dev-vm-vmware`, so older commands still work.

The CPU architecture isn't set in the flake. Each VM's generated `hardware-configuration.nix` sets it through `nixpkgs.hostPlatform`, so the same configuration builds for whichever architecture the VM runs on.

Every VM runs:

- GNOME desktop
- NixOS with flakes
- Home Manager-managed user environment

You can run several VMs on the same hypervisor. Each one gets its own hostname (see [Applying The Config](#applying-the-config)).

The default user configured by this repo is `devenv`, with home directory `/home/devenv`.

## What It Configures

Both configurations include:

- GNOME desktop with GDM
- Guest integration for the hypervisor: VMware guest tools through `open-vm-tools`, or the QEMU guest agent and SPICE agent on Proxmox
- NetworkManager
- OpenSSH
- Nix flakes and `nix-command`
- Home Manager
- Zsh, Git, Neovim, Herdr, direnv, zoxide, Starship, Ghostty, and common development CLI tools
- Coding agents: OpenCode, Claude Code, and pi
- A [T3 Code server](#t3-code-server) for the `devenv` user, started at boot, with telemetry turned off
- Claude Code, OpenCode, pi, Bun, Herdr, and T3 Code come from `nixos-unstable`, since they release faster than the stable channel
- Local DNS preference for `192.168.1.1`
- Allow `8080` for testing apps on VM host
- Allow `3773` for the T3 Code server
- Optional Tailscale, turned on per VM (see [Tailscale HTTPS](#tailscale-https))
- Disabled GNOME automatic screen blanking

## Set Up A New VM

1. Create the VM and install NixOS with the username `devenv`. See [VMware Fusion Setup](#vmware-fusion-setup) or [Proxmox Setup](#proxmox-setup).
2. Log in at the VM's console and run the bootstrap command. Type your password when `sudo` asks for it:

   ```sh
   nix --extra-experimental-features 'nix-command flakes' run github:seanbeirnes/nixos-vms#bootstrap
   ```

   Bootstrap clones this repo to `~/Desktop/repos/nixos-vms` (or updates the clone), runs [`./bin/apply-dev-vm`](#applying-the-config), runs [`sync-configs`](#common-commands), and prints this VM's hostname. It passes `DEV_VM_HOST`, `DEV_VM_HOSTNAME`, and any arguments after `--` on to `apply-dev-vm`:

   ```sh
   DEV_VM_HOSTNAME=proxmox-dev-2 nix --extra-experimental-features 'nix-command flakes' run github:seanbeirnes/nixos-vms#bootstrap -- --show-trace
   ```

   When it finishes, reboot (`sudo reboot`), so the VM takes its new hostname, your login shell becomes zsh, and the T3 Code server starts.

3. [Pair the T3 Code desktop app](#pair-the-mac-desktop-app) on your Mac with the VM, then sign in to Claude Code on the VM (run `claude`).
4. Run `gh auth login` on the VM yourself and sign in to a GitHub account. Choose SSH, and let it generate a new key and upload it to that account. Each VM gets its own key, so when `gh` asks for the key's title, enter `devenv-<hostname>` (for example `devenv-dev-vm-proxmox-a1b2`, using the hostname bootstrap printed) to find or revoke one VM's key later. If [Tailscale](#tailscale-https) is on for this VM, also run `sudo tailscale up --operator=devenv` yourself, since an agent can't type the `sudo` password.
5. A T3 agent on the VM can do the rest:
   - Trust GitHub's SSH host keys. These are GitHub's server keys, the same on every VM, not this VM's own key. `gh auth login` doesn't add them to `~/.ssh/known_hosts`, and `sync-configs` won't answer an SSH prompt, so without this step it can't clone the private repo. `gh` fetches the keys over HTTPS:

     ```sh
     gh api meta --jq '.ssh_keys[] | "github.com " + .' >> ~/.ssh/known_hosts
     ```

   - Rerun `sync-configs`, which now also clones and links `agents-private`. If you gave the SSH key a passphrase, this step is skipped, since `sync-configs` can't ask for it.
   - Start the other logins and relay their codes, such as OpenCode's.

   Optional: run `ssh-copy-id devenv@<hostname>` from your Mac to log in over SSH. Use the VM's IP address if your Mac can't resolve its hostname.

Bootstrap uses the checkout at `~/Desktop/repos/nixos-vms`. On an older VM whose checkout is somewhere else, keep applying from that checkout with `./bin/apply-dev-vm`, since a fresh clone wouldn't have the VM's `hosts/dev-vm/local.nix` (its hostname and Tailscale setting).

## VMware Fusion Setup

1. Download the Graphical ISO image of NixOS, 64-bit ARM, from <https://nixos.org/download/>.
2. Choose the ISO when creating the VM in VMware Fusion.
3. For **Select the operating system for this virtual machine**, select **Linux** -> **Other Linux 6.x kernel 64-bit Arm**.
4. Complete the graphical NixOS installation, with the username `devenv`.
5. Boot into the installed VM and continue at step 2 of [Set Up A New VM](#set-up-a-new-vm).

## Proxmox Setup

1. Download the Graphical ISO image of NixOS, Intel/AMD 64-bit (`x86_64`), from <https://nixos.org/download/>, and upload it to an ISO storage on the Proxmox node.
2. Create a VM with these settings (the rest can stay at their defaults):
   - **OS**: the NixOS ISO, guest OS type **Linux**.
   - **System**:
     - **Machine**: `q35`.
     - **BIOS**: **OVMF (UEFI)**. The config boots with systemd-boot, so SeaBIOS won't work.
     - **Add EFI Disk**: ticked, with **Pre-Enroll keys** *unticked*. Pre-enrolled keys turn on Secure Boot, and the NixOS ISO then fails to boot with an "Access Denied" error.
     - **Qemu Agent**: ticked. The `dev-vm-proxmox` config runs the agent inside the VM.
     - **Graphic card**: **VirtIO-GPU**, or **SPICE** if you connect with a SPICE client (the config runs the SPICE agent for clipboard sharing and display resizing).
     - **SCSI Controller**: **VirtIO SCSI single** or **VirtIO SCSI**.
   - **Disks**: bus **SCSI**.
   - **Network**: model **VirtIO (paravirtualized)**.
3. Complete the graphical NixOS installation, with the username `devenv`.
4. Boot into the installed VM and continue at step 2 of [Set Up A New VM](#set-up-a-new-vm).

## Applying The Config

[Bootstrap](#set-up-a-new-vm) applies the config on a new VM. To apply it again, for example after changing it, run this from the repo root (`~/Desktop/repos/nixos-vms`) inside the VM:

```sh
./bin/apply-dev-vm
```

The apply command:

- Picks the host configuration from `systemd-detect-virt`: `vmware` uses `dev-vm-vmware`, `kvm` uses `dev-vm-proxmox`
- Copies `/etc/nixos/hardware-configuration.nix` into `hosts/dev-vm/hardware-configuration.nix`, and stops if that file doesn't set `nixpkgs.hostPlatform`
- On the first run, creates `hosts/dev-vm/local.nix` with this VM's hostname. It never overwrites an existing `local.nix`
- Keeps those per-VM files local and untracked
- Creates a temporary source tree that includes the ignored per-VM files
- Locks the flake inputs and copies `flake.lock` back to the repo, so it can be committed. Run `nix flake update` to move to newer inputs
- Runs `nixos-rebuild switch --flake ...#<host>` through `sudo`

The default hostname is `dev-vm-<vmware|proxmox>-<first 4 characters of /etc/machine-id>`, for example `dev-vm-proxmox-3f9a`, so several VMs on one network get different names. To choose the name, set `DEV_VM_HOSTNAME` on the first run:

```sh
DEV_VM_HOSTNAME=proxmox-dev-2 ./bin/apply-dev-vm
```

To rename a VM later, edit `networking.hostName` in `hosts/dev-vm/local.nix` and apply again.

VMs set up before per-VM hostnames were called `dev-vm`. To keep that name, set it on the first apply after updating, otherwise the VM is renamed to `dev-vm-<hypervisor>-<id>`:

```sh
DEV_VM_HOSTNAME=dev-vm ./bin/apply-dev-vm
```

A cloned VM keeps the original's `/etc/machine-id` and `local.nix`, and so its hostname too. In each clone, delete `hosts/dev-vm/local.nix` and either set `DEV_VM_HOSTNAME` or regenerate the machine ID before applying.

If `systemd-detect-virt` reports a different hypervisor, or you want to force a configuration, set `DEV_VM_HOST`:

```sh
DEV_VM_HOST=dev-vm-proxmox ./bin/apply-dev-vm
```

The script appends any extra arguments to `nixos-rebuild`:

```sh
./bin/apply-dev-vm --show-trace
```

The flake also exposes the apply command as an app:

```sh
nix run .#apply-dev-vm
```

When using `nix run`, pass script arguments after `--`:

```sh
nix run .#apply-dev-vm -- --show-trace
```

## T3 Code Server

Each VM runs a [T3 Code](https://github.com/pingdotgg/t3code) server, so the T3 Code desktop app on your Mac can run coding agents (Claude Code, OpenCode, pi) on the VM.

What runs:

- `t3 serve --port 3773 --lan` as the systemd user service `t3code`, for `devenv` only. Lingering is on for `devenv`, so the service starts at boot without a desktop login
- The server gets the system and user profiles on its `PATH`, plus your login shell's `PATH`, so it finds `claude`, `opencode`, `pi`, `git`, and `gh`. Sign in to each agent (and run `gh auth login`) on the VM once, as usual
- Port `3773` is pinned and open in the firewall. Anyone on the LAN can reach it, so the one-time pairing link is what keeps other devices out. LAN traffic is plain HTTP, so it isn't encrypted; Tailscale HTTPS (below) is
- A paired device can run agents and terminals as `devenv`, which can become root on the VM. Only pair devices you trust
- The `t3` command is installed, for pairing and checks

### Pair The Mac Desktop App

Keep the desktop app on your Mac at the same version as the server (`t3 --version` on the VM).

1. On the VM, run:

   ```sh
   t3 pair
   ```

   It prints a one-time pairing link and a QR code.

2. In the desktop app on the Mac, open **Settings → Environments → Add environment** and paste the link. You can also open the printed `t3code://pair` link on the Mac.

Treat pairing links like passwords. Each link pairs one device; run `t3 pair` again for the next one.

### Telemetry

The server's telemetry is locked off:

- `/etc/t3code/policy.json` is a [managed policy](https://github.com/pingdotgg/t3code/blob/v0.1.8/docs/user/managed-policy.md) with `"telemetry": false`. Settings shows the VM as managed by `nixos-vms`. The policy restricts nothing else: every provider and setting stays your choice
- The service also sets `T3CODE_TELEMETRY_ENABLED=false` and `OTEL_SDK_DISABLED=true`

This doesn't cover the clients:

- The Mac desktop app reads `T3CODE_TELEMETRY_ENABLED` from your shell profile. Add `export T3CODE_TELEMETRY_ENABLED=false` to `~/.zshrc` on the Mac and restart the app
- Browser and mobile clients (including app.t3.codes) still send their own relay connection traces; T3 Code has no setting to stop them
- **Publish agent activity** (for mobile notifications) is a separate setting under **Settings → Sharing & access**

### Tailscale HTTPS

Tailscale is off by default. To turn it on for one VM, add this to its `hosts/dev-vm/local.nix`:

```nix
{
  networking.hostName = "dev-vm-proxmox-3f9a"; # keep your existing line
  devVm.tailscale.enable = true;
}
```

Then:

1. Apply the config with `./bin/apply-dev-vm`. This runs `tailscaled`, makes `devenv` a Tailscale operator (so it can run `tailscale serve` without `sudo`), and sets the T3 server to start with `--tailscale-serve`. A running server picks that up at the restart in step 4.
2. Log the VM in to your tailnet once:

   ```sh
   sudo tailscale up --operator=devenv
   ```

   Keep `--operator=devenv`: a plain `tailscale up` resets the operator, and the server then can't set up Tailscale HTTPS.

3. In the [Tailscale admin console](https://login.tailscale.com/admin/dns), turn on **MagicDNS** and **HTTPS Certificates**.
4. Restart the server, since it sets up Tailscale Serve only when it starts:

   ```sh
   systemctl --user restart t3code
   ```

5. Pair over Tailscale. The link uses an address like `https://<hostname>.<tailnet>.ts.net/`:

   ```sh
   t3 pair --tailscale
   ```

At boot, the server waits up to about 80 seconds for Tailscale. If Tailscale is logged out or stopped, the server starts without Tailscale HTTPS and keeps serving the LAN.

### Check The Server

```sh
systemctl --user status t3code
journalctl --user -u t3code -e
t3 policy show
```

`t3 policy show` should list the `nixos-vms` policy with telemetry off, and say the running server loaded it.

Applying the config doesn't restart a running server, since that would end every T3 terminal and agent turn, including one running the apply. After an apply that updates T3 Code, the policy, or the Tailscale setting, restart it yourself:

```sh
systemctl --user restart t3code
```

If the service isn't running after the first apply, start it with `systemctl --user start t3code`, or reboot.

The service stops retrying after 5 failed starts in 5 minutes, for example when another process holds port `3773`. Check the log, fix the cause, then run `systemctl --user reset-failed t3code` and start it again.

## Railway CLI Setup

The Railway CLI is installed separately from NixOS so it can follow Railway's current releases instead of the version packaged in Nixpkgs. The Home Manager configuration includes `~/.railway/bin` in `PATH`.

After applying the VM configuration and opening a new shell, follow Railway's CLI installation instructions:

```sh
bash <(curl -fsSL railway.com/install.sh)
```

Other information can be found in [Railway's CLI docs](https://docs.railway.com/cli).

## Local Hardware Config

`hosts/dev-vm/hardware-configuration.nix` and `hosts/dev-vm/local.nix` are intentionally ignored by git.

`hardware-configuration.nix` is generated by NixOS and contains VM-specific hardware, disk, filesystem, and boot details, including the CPU architecture (`nixpkgs.hostPlatform`). It should exist locally in each VM, but it should not be edited manually or committed unless you intentionally want to pin the repo to one specific VM disk layout.

`local.nix` holds settings for one VM, such as its hostname and whether it runs [Tailscale](#tailscale-https). The apply script creates it on the first run, and you can edit it freely. If it's missing, the hostname falls back to `dev-vm`.

If needed, recreate the hardware config manually with:

```sh
cp /etc/nixos/hardware-configuration.nix hosts/dev-vm/hardware-configuration.nix
```

Then apply the config:

```sh
./bin/apply-dev-vm
```

## VMware Keyboard Mappings

VMware Fusion can translate macOS keyboard shortcuts before they reach the Linux guest. This is often a better place to configure Mac-like navigation than the NixOS or GNOME config.

Recommended host-side mappings:

| macOS Shortcut | Linux Guest Shortcut | Purpose |
| --- | --- | --- |
| `Cmd+Q` | `Alt+F4` | Close the active window |
| `Cmd+Left` | `Home` | Move to beginning of line |
| `Cmd+Right` | `End` | Move to end of line |
| `Cmd+Backspace` | `Ctrl+U` | Delete line |
| `Option+Left` | `Ctrl+Left` | Move one word left |
| `Option+Right` | `Ctrl+Right` | Move one word right |
| `Option+Backspace` | `Ctrl+Backspace` | Delete previous word |

Be careful with global copy/paste remaps:

- `Cmd+C` -> `Ctrl+C` works as copy in many GUI apps, but `Ctrl+C` interrupts running processes in terminals.
- In Ghostty, `Ctrl+C` copies only when text is selected, and pasting is `Ctrl+Shift+V`. Plain `Ctrl+V` goes to the program in the terminal, such as Neovim's visual-block mode.

## Common Commands

Apply the VM config:

```sh
./bin/apply-dev-vm
```

Run a plain rebuild manually, naming the configuration for your hypervisor. The `path:` prefix makes Nix read the working tree directly: a plain `.#` reference only sees files tracked by git, which leaves out the ignored hardware config and `local.nix`.

```sh
sudo nixos-rebuild switch --flake "path:$PWD#dev-vm-vmware"
sudo nixos-rebuild switch --flake "path:$PWD#dev-vm-proxmox"
```

Update the Neovim config and the coding agent config (Claude Code and OpenCode instructions, skills, and settings) from their GitHub repos, `seanbeirnes/vim-config` and `seanbeirnes/agents`. It clones them into `~/.config/nvim` and `~/.config/agents` the first time, then runs the agents repo's `install.sh`. Safe to rerun:

```sh
sync-configs
```

Check the configured resolver:

```sh
cat /etc/resolv.conf
```

Check the current system generation:

```sh
nixos-rebuild list-generations
```

## Troubleshooting

### Missing Hardware Config

If rebuilds fail because `hosts/dev-vm/hardware-configuration.nix` cannot be found, copy the generated NixOS hardware config into the local ignored path:

```sh
cp /etc/nixos/hardware-configuration.nix hosts/dev-vm/hardware-configuration.nix
```

Then rerun:

```sh
./bin/apply-dev-vm
```

### Sudo Wrapper Error

If `sudo` reports that it must be owned by `uid 0` and have the setuid bit set, use the NixOS wrapper path:

```sh
/run/wrappers/bin/sudo nixos-rebuild switch --flake "path:$PWD#dev-vm-vmware"
```

On Proxmox, use `#dev-vm-proxmox`.

The apply script already prefers `/run/wrappers/bin/sudo` when it exists.

### DNS Does Not Stick

This config sets `192.168.1.1` through both `networking.nameservers` and NetworkManager's `insertNameservers` option. If `/etc/resolv.conf` still changes after reboot, inspect the active NetworkManager connection in the VM and check whether DHCP (VMware's network, or your LAN's DHCP server on Proxmox) is injecting different DNS settings.

### VMware Guest Integration

VMware guest tools are enabled through:

```nix
virtualisation.vmware.guest.enable = true;
```

This enables the open-source VMware guest integration used by NixOS. It is set in `hosts/vmware/default.nix`.

### Proxmox Guest Integration

`hosts/proxmox/default.nix` enables the QEMU guest agent and the SPICE agent:

```nix
services.qemuGuest.enable = true;
services.spice-vdagentd.enable = true;
```

The guest agent only works when **Qemu Agent** is ticked in the VM's Proxmox **Options**. If Proxmox reports that the agent isn't running, tick it, then shut the VM down and start it again (a reboot from inside the VM isn't enough).

### NixOS ISO Fails With "Access Denied" On Proxmox

Secure Boot is on because the EFI disk was created with **Pre-Enroll keys** ticked. With the VM stopped, remove the EFI disk under **Hardware** and add it again with **Pre-Enroll keys** unticked.
