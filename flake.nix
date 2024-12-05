{
  description = "A convention over configuration framework for Nix flakes";

  inputs = {
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";

    flakeParts.url = "github:hercules-ci/flake-parts";
    flakeParts.inputs.nixpkgs-lib.follows = "nixpkgs";

    homeManager.url = "github:nix-community/home-manager";
    homeManager.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    inputs@{
      devenv,
      flakeParts,
      ...
    }:
    flakeParts.lib.mkFlake { inherit inputs; } {
      imports = [
        devenv.flakeModule
        flakeParts.flakeModules.flakeModules
        ./checks.nix
      ];

      flake =
        { lib, ... }:
        {
          lib = import ./lib.nix { inherit lib; };
          flakeModules = rec {
            hotwire = ./flake-modules/hotwire;

            darwinOutputs = ./flake-modules/darwin-outputs.nix;
            homeManagerOutputs = ./flake-modules/home-manager-outputs.nix;

            default = hotwire;
          };
          templates = {
            minimal = {
              path = ./templates/minimal;
              description = "A minimal template utilizing hotwire.";
            };
            example = {
              path = ./templates/example;
              description = "An example exercising most of hotwire's features.";
            };
          };
        };

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        { lib, pkgs, ... }:
        {
          devenv.shells.default = {
            languages.nix.enable = true;
            starship.enable = true;
            pre-commit.hooks = {
              deadnix.enable = true;
              nil.enable = true;
              nixfmt-rfc-style.enable = true;
              statix.enable = true;
            };
            containers.processes.derivation = pkgs.emptyDirectory;
            containers.shell.derivation = pkgs.emptyDirectory;
          };
          packages = {
            container-processes = lib.mkForce pkgs.emptyDirectory;
            container-shell = lib.mkForce pkgs.emptyDirectory;
          };
        };
    };
}
