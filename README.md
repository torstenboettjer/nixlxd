# Run Qemu images with lxd on NixOS
To run QEMU-based virtual machines in [LXD](https://linuxcontainers.org/lxd/) on a [NixOS](https://nixos.org/) host, your system needs hardware virtualization, OVMF UEFI firmware, and the qemu tools properly wired into your path. You can set this up declaratively using [NixOS Flakes](https://discuss.linuxcontainers.org/t/unable-to-create-a-vm-on-nixos/12314) or your base configuration.

## Enable LXD and QEMU on the Host
Add the following options to your /etc/nixos/configuration.nix file to correctly initialize LXD and map the essential dependencies needed for QEMU.nix

```nix
{ pkgs, ... }:

{
  # Ensure KVM/QEMU modules are loaded
  boot.kernelModules = [ "kvm-amd" "kvm-intel" "vhost-vsock" ];

  # Enable LXD
  virtualisation.lxd = {
    enable = true;
    recommendedSysctlSettings = true;
  };

  # Make QEMU available for the LXD daemon
  virtualisation.lxd.qemuPackage = pkgs.qemu_kvm;

  # Optionally add your user to the lxd group so you don't need sudo
  users.users.your_username.extraGroups = [ "lxd" ];
}
```

Run `sudo nixos-rebuild switch` to apply the host configuration.

## Initialize LXD Networking
LXD requires a bridge network to assign IPs to virtual machines. You can initialize this declaratively in your configuration or interactively by running the following command: 
```sh
sudo lxd init
```

*Note: Accept the defaults for storage and networking unless you require custom bridge settings.*

## Launch a NixOS VM
Since NixOS images on the official LXD remote server have been deprecated in favor of its community fork [Incus](https://linuxcontainers.org/incus/), you can easily build a custom NixOS QEMU image or use `distrobuilder` to import a generic cloud image. 

Once your image is ready and imported, launch your VM instance:

```sh
# Import your base image (if you built a custom one)
lxc image import <metadata.tar.gz> <rootfs.squashfs> --alias nixos-base

# Launch a QEMU VM with LXD
lxc init my-nix-vm nixos-base --vm
lxc config set my-nix-vm security.secureboot=false
lxc config set my-nix-vm limits.cpu 2
lxc config set my-nix-vm limits.memory 4GB
lxc start my-nix-vm
```

## Important Notes for NixOS Guests
* **Cloud-Init:**  The deployed image likely uses cloud-init to fetch a default password. Check your LXD console once the VM starts up.
* **Configuration Overlays:** Do not copy the base configuration.nix when making tweaks to your virtual guest. Instead, create a new guest-specific configuration that defines only the packages or services you want to add on top of the base image.
