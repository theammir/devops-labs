{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  virtualisation = {
    qemu.options = [
      "-machine virt,gic-version=max,accel=hvf"
      "-cpu host"
    ];
    forwardPorts = [
      {
        from = "host";
        host.port = 2222;
        guest.port = 22;
      }
      {
        from = "host";
        host.port = 8080;
        guest.port = 80;
      }
    ];
    memorySize = 2048;
    cores = 1;
    graphics = false;
  };
}
