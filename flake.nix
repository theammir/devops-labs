{
  nixConfig = {
    extra-platforms = [ "aarch64-linux" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    mywebapp.url = "path:./mywebapp";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      mywebapp,
    }:
    let
      guestSystem = "aarch64-linux";

      nixosConfig = nixpkgs.lib.nixosSystem {
        system = guestSystem;
        modules = [
          ./nixos/configuration.nix
          ./nixos/vm.nix
          {
            _module.args.mywebapp = mywebapp.packages.${guestSystem}.default;
          }
        ];
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            qemu
            e2fsprogs
            just
          ];
        };

        apps.vm = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "run-vm" ''
              NIX_DISK_IMAGE=$(readlink -f "''${NIX_DISK_IMAGE:-./nixos.qcow2}")

              if ! test -e "$NIX_DISK_IMAGE"; then
                echo "Creating disk image..."
                TEMP=$(mktemp)
                ${pkgs.qemu}/bin/qemu-img create -f raw "$TEMP" 1024M
                ${pkgs.e2fsprogs}/bin/mkfs.ext4 -L nixos "$TEMP"
                ${pkgs.qemu}/bin/qemu-img convert -f raw -O qcow2 "$TEMP" "$NIX_DISK_IMAGE"
                rm "$TEMP"
              fi

              TMPDIR=$(mktemp -d)
              mkdir -p "$TMPDIR/xchg"

              exec ${pkgs.qemu}/bin/qemu-system-aarch64 \
                -machine virt,gic-version=max,accel=hvf \
                -cpu host \
                -name nixos \
                -m 2048 \
                -smp 1 \
                -device virtio-rng-pci \
                -net nic,netdev=user.0,model=virtio \
                -netdev user,id=user.0,hostfwd=tcp::2222-:22 \
                -virtfs local,path=/nix/store,security_model=none,mount_tag=nix-store \
                -virtfs local,path="$TMPDIR/xchg",security_model=none,mount_tag=shared \
                -virtfs local,path="$TMPDIR/xchg",security_model=none,mount_tag=xchg \
                -drive cache=writeback,file="$NIX_DISK_IMAGE",id=drive1,if=none,index=1,werror=report \
                -device virtio-blk-pci,bootindex=1,drive=drive1,serial=root \
                -kernel ${nixosConfig.config.system.build.kernel}/Image \
                -initrd ${nixosConfig.config.system.build.initialRamdisk}/initrd \
                -append "$(cat ${nixosConfig.config.system.build.toplevel}/kernel-params) init=${nixosConfig.config.system.build.toplevel}/init regInfo=${nixosConfig.config.system.build.toplevel}/registration console=tty0 console=ttyAMA0,115200n8" \
                -serial stdio \
                -monitor none \
                -nographic \
                $QEMU_OPTS \
                "$@"
            ''
          );
        };
        packages.vm = nixosConfig.config.system.build.vm;
      }
    )
    // {
      nixosConfigurations.myvm-interactive = nixosConfig;
    };
}
