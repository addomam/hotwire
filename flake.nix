{
  description = "A convention over configuration framework for Nix flakes";

  inputs = {
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    flakeParts.url = "github:hercules-ci/flake-parts";
    flakeParts.inputs.nixpkgs-lib.follows = "nixpkgs";

    homeManager.url = "github:nix-community/home-manager";
    homeManager.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    treefmt.url = "github:numtide/treefmt-nix";
    treefmt.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {flakeParts, ...}:
    flakeParts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.treefmt.flakeModule
        flakeParts.flakeModules.flakeModules
      ];

      flake = {lib, ...}: {
        lib = import ./lib.nix {inherit lib;};
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

      perSystem = {...}: {
        treefmt = {
          projectRootFile = "flake.nix";

          programs.alejandra.enable = true;
          programs.deadnix.enable = true;
          programs.prettier.enable = true;
        };
      };
    };
}
