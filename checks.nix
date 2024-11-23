{
  config,
  inputs,
  flake-parts-lib,
  ...
}:
let
  allInputs = inputs // {
    hotwire = {
      inherit (config.flake) flakeModules;
    };
  };
  templatesExample =
    flake-parts-lib.mkFlake
      {
        inputs = allInputs;
        moduleLocation = ./templates/example;
      }
      (
        {
          inputs,
          moduleLocation,
          config,
          ...
        }:
        {
          imports = [
            inputs.hotwire.flakeModules.hotwire
            inputs.hotwire.flakeModules.darwinOutputs
            inputs.hotwire.flakeModules.homeManagerOutputs
          ];

          systems = [
            "aarch64-darwin"
            "aarch64-linux"
            "x86_64-darwin"
            "x86_64-linux"
          ];

          hotwire.enable = true;
          hotwire.basePath = moduleLocation;

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
in
{
  flake.checks = {
    x86_64-darwin.templatesExampleSystem =
      templatesExample.darwinConfigurations.intel.config.system.build.toplevel;
    aarch64-darwin.templatesExampleSystem =
      templatesExample.darwinConfigurations.appleSilicon.config.system.build.toplevel;
  };

  perSystem =
    { system, lib, ... }:
    {
      checks =
        with lib.attrsets;
        mapAttrs' (name: nameValuePair "templatesExample-${name}") templatesExample.checks."${system}";
    };
}
