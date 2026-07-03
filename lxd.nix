{ config, pkgs, ... }:

{
  # Ensure KVM/QEMU modules are loaded
  boot.kernelModules = [ "kvm-amd" "kvm-intel" "vhost-vsock" ];

  # Enable LXD
  virtualisation.lxd = {
    enable = true;
    recommendedSysctlSettings = true; # Optimizes kernel settings for LXD
    preseed = {
      networks = [
        {
          name = "lxdbr0";
          type = "bridge";
          config = {
            "ipv4.address" = "10.0.100.1/24";
            "ipv4.nat" = "true";
          };
        }
      ];
      profiles = [
        {
          name = "default";
          devices = {
            eth0 = {
              name = "eth0";
              network = "lxdbr0";
              type = "nic";
            };
            root = {
              path = "/";
              pool = "default";
            };
          };
        }
      ];
      storage_pools = [
        {
          name = "default";
          driver = "dir"; # Or "zfs" or "btrfs" if you prefer
        }
      ];
    };
  };

  # Make QEMU available for the LXD daemon
  virtualisation.lxd.qemuPackage = pkgs.qemu_kvm;

  # Allow your user to run lxc commands without sudo
  users.users.your_username = {
    isNormalUser = true;
    extraGroups = [ "lxd" "networkmanager" ];
  };
}
