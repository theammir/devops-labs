{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./modules/common.nix
    ./modules/mywebapp.nix
    ./modules/postgresql.nix
    ./modules/nginx.nix
  ];

  _module.args.mywebapp = pkgs.callPackage ./mywebapp-pkg.nix { };

  services.mywebapp.configFile = ./config.toml;

  boot.loader = lib.mkMerge [
    (lib.mkIf pkgs.stdenv.isAarch64 {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    })
    (lib.mkIf pkgs.stdenv.isx86_64 {
      grub.enable = true;
      grub.device = "/dev/vda";
    })
  ];

  boot.initrd.availableKernelModules = [
    "virtio_blk"
    "virtio_pci"
    "virtio_net"
    "virtio_scsi"
    "9p"
    "9pnet_virtio"
    "ext4"
  ];

  fileSystems."/" = {
    device = if pkgs.stdenv.isAarch64 then "/dev/vda2" else "/dev/vda1";
    fsType = "ext4";
  };
  fileSystems."/boot" = lib.mkIf pkgs.stdenv.isAarch64 {
    device = "/dev/vda1";
    fsType = "vfat";
  };

  networking.hostName = "mywebapp";
}
