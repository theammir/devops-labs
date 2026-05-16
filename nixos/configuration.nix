{ ... }:
{
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
  users.users.app = {
    # TODO: whatever app owns to run itself
    isNormalUser = true;
    initialPassword = "123123";
  };
  users.users.operator = {
    # TODO: minimal permissions to operate the app
    isNormalUser = true;
    initialPassword = "123123";
  };

  system.stateVersion = "25.11";
}
