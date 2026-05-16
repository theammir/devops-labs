{ ... }:
{
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  users.users.root.initialPassword = "root";

  virtualisation.qemu.options = [
    "-accel hvf"
    "-cpu host"
  ];
  virtualisation.forwardPorts = [
    {
      from = "host";
      host.port = 2222;
      guest.port = 22;
    }
  ];
  virtualisation.memorySize = 2048;
  virtualisation.graphics = false;
}
