{ ... }:
{
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

  users.users.root.hashedPassword = "!";

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };

  networking.firewall.allowedTCPPorts = [
    22
    80
  ];

  system.stateVersion = "26.05";
}
