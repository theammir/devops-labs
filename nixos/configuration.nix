{ ... }:
{
  imports = [
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

  users.users.student = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "12345678";
  };
  users.users.teacher = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "12345678";
  };
  users.users.operator = {
    # TODO: minimal permissions to operate the app
    isNormalUser = true;
    initialPassword = "12345678";
  };

  networking.firewall.allowedTCPPorts = [
    80
  ];

  system.stateVersion = "26.05";
}
