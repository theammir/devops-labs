{
  description = "Mywebapp";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    uv2nix.url = "github:pyproject-nix/uv2nix";
    uv2nix.inputs.nixpkgs.follows = "nixpkgs";
    pyproject-nix.url = "github:pyproject-nix/pyproject.nix";
    pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      uv2nix,
      pyproject-nix,
      ...
    }:
    let
      system = "aarch64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };
      overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };
      python = pkgs.python313;
      pythonSet =
        (pkgs.callPackage pyproject-nix.lib.renderers.withPackages {
          inherit python;
        }).overrideScope
          overlay;

      package = pythonSet.mkVirtualEnv "mywebapp-env" workspace.deps.default;
    in
    {
      packages.${system}.default = package;

      apps.${system}.default = {
        type = "app";
        program = "${package}/bin/mywebapp";
      };
    };
}
