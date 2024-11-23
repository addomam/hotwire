{
  inputs = {
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:lnl7/nix-darwin";
    flakeParts.inputs.nixpkgs-lib.follows = "nixpkgs";
    flakeParts.url = "github:hercules-ci/flake-parts";
    homeManager.inputs.nixpkgs.follows = "nixpkgs";
    homeManager.url = "github:nix-community/home-manager";
    hotwire.url = "github:addomam/hotwire";
    hotwire.inputs = {
      darwin.follows = "darwin";
      flakeParts.follows = "flakeParts";
      homeManager.follows = "homeManager";
      nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ flakeParts, hotwire, ... }:
    flakeParts.lib.mkFlake { inherit inputs; } (
      { config, ... }:
      {
        imports = [
          hotwire.flakeModules.hotwire
          hotwire.flakeModules.darwinOutputs
          hotwire.flakeModules.homeManagerOutputs
        ];

        systems = [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-darwin"
          "x86_64-linux"
        ];

        hotwire.enable = true;

        flake = {
          checks = {
            aarch64-darwin = {
              darwinConfiguration = config.flake.darwinConfigurations.appleSilicon.config.system.build.toplevel;
              homeConfiguration = config.flake.homeConfigurations.appleSilicon.config.system.build.toplevel;
            };
            aarch64-linux = {
              homeConfiguration = config.flake.homeConfigurations.arm.config.system.build.toplevel;
              nixosConfiguration = config.flake.nixosConfigurations.arm.config.system.build.toplevel;
            };
            x86_64-darwin = {
              darwinConfiguration = config.flake.darwinConfigurations.intel.config.system.build.toplevel;
              homeConfiguration = config.flake.homeConfigurations.intelMac.config.system.build.toplevel;
            };
            x86_64-linux = {
              homeConfiguration = config.flake.homeConfigurations.intelLinux.config.system.build.toplevel;
              nixosConfiguration = config.flake.nixosConfigurations.intel.config.system.build.toplevel;
            };
          };
        };
      }
    );
}
