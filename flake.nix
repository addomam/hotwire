{
  description = "A convention over configuration framework for Nix flakes";

  inputs = {
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    flakeParts.url = "github:hercules-ci/flake-parts";
    flakeParts.inputs.nixpkgs-lib.follows = "nixpkgs";

    gitHooks.url = "github:cachix/git-hooks.nix";
    gitHooks.inputs.nixpkgs.follows = "nixpkgs";

    homeManager.url = "github:nix-community/home-manager";
    homeManager.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    treefmt.url = "github:numtide/treefmt-nix";
    treefmt.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      flakeParts,
      gitHooks,
      treefmt,
      ...
    }:
    flakeParts.lib.mkFlake { inherit inputs; } {
      imports = [
        flakeParts.flakeModules.flakeModules
        gitHooks.flakeModule
        treefmt.flakeModule
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
        { config, pkgs, ... }:
        {
          treefmt = {
            programs.nixfmt.enable = true;
          };
          pre-commit.settings.hooks = {
            deadnix.enable = true;
            nil.enable = true;
            statix.enable = true;
            treefmt.enable = true;
          };
          devShells.default = pkgs.mkShellNoCC {
            shellHook = ''
              ${config.pre-commit.installationScript}
            '';
            buildInputs = with pkgs; [
              nixd
            ];
          };
        };
    };
}
