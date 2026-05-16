{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  services.openssh = {
    enable = true;
  };

  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  virtualisation.qemu.options = [
    "-accel tcg"
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
