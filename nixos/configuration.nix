{ ... }:
{
  imports = [
    ./common.nix
    ./mywebapp.nix
    ./postgresql.nix
    ./nginx.nix
  ];

  fileSystems."/" = {
    device = "/dev/vda";
    fsType = "ext4";
  };
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };
}
