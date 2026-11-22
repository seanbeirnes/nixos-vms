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
- Claude Code, OpenCode, pi, Bun, and Herdr come from `nixos-unstable`, since they release faster than the stable channel
- Local DNS preference for `192.168.1.1`
- Allow `8080` for testing apps on VM host
- Disabled GNOME automatic screen blanking

## VMware Fusion Setup

1. Download the Graphical ISO image of NixOS, 64-bit ARM, from <https://nixos.org/download/>.
2. Choose the ISO when creating the VM in VMware Fusion.
3. For **Select the operating system for this virtual machine**, select **Linux** -> **Other Linux 6.x kernel 64-bit Arm**.
4. Complete the graphical NixOS installation.
5. Boot into the installed VM.
6. Clone this repo inside the VM.
7. Apply the repo configuration.

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
3. Complete the graphical NixOS installation.
4. Boot into the installed VM.
5. Clone this repo inside the VM.
6. Apply the repo configuration.

## Applying The Config

From the repo root inside the VM, run:

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

`local.nix` holds settings for one VM, such as its hostname. The apply script creates it on the first run, and you can edit it freely. If it's missing, the hostname falls back to `dev-vm`.

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
