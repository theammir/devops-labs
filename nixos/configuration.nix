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
    initialPassword = "123123";
  };
  users.users.teacher = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "123123";
  };
  users.users.operator = {
    # TODO: minimal permissions to operate the app
    isNormalUser = true;
    initialPassword = "123123";
  };

  networking.firewall.allowedTCPPorts = [
    80
  ];

  system.stateVersion = "25.11";
}
