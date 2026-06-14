{
  description = "mywebapp flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { nixpkgs, ... }:
    let
      system = "aarch64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        pname = "mywebapp";
        version = "0.1.0";
        src = ./.;

        installPhase = ''
          mkdir -p $out/lib/mywebapp
          cp -r . $out/lib/mywebapp
        '';
      };
    };
}
