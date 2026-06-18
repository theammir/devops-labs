{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mywebapp.url = "path:./mywebapp";
  };

  outputs =
    {
      self,
      nixpkgs,
      mywebapp,
    }:
    let
      hostSystem = "aarch64-darwin";
      guestSystem = "aarch64-linux";
      hostPkgs = nixpkgs.legacyPackages.${hostSystem};
      nixosConfig = nixpkgs.lib.nixosSystem {
        system = guestSystem;
        modules = [
          ./nixos/configuration.nix
          ./nixos/postgresql.nix
          ./nixos/nginx.nix
          ./nixos/vm.nix
          {
            _module.args.mywebapp = mywebapp.packages.${guestSystem}.default;
            services.mywebapp.configFile = ./mywebapp/config.example.toml;
            virtualisation.host.pkgs = hostPkgs;
          }
        ];
      };
    in
    {
      devShells.${hostSystem}.default = hostPkgs.mkShellNoCC {
        packages = with hostPkgs; [
          qemu
          just
          expect
        ];
      };

      apps.${hostSystem}.vm = {
        type = "app";
        program = "${nixosConfig.config.system.build.vm}/bin/run-${nixosConfig.config.networking.hostName}-vm";
      };
      packages.${hostSystem}.vm = nixosConfig.config.system.build.vm;
    }
    // {
      nixosConfigurations.myvm-interactive = nixosConfig;
    };
}
