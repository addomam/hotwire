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
  exampleFlake =
    flake-parts-lib.mkFlake
      {
        inputs = allInputs;
        moduleLocation = ./templates/example;
      }
      (
        { inputs, moduleLocation, ... }:
        {
          imports = [
            inputs.hotwire.flakeModules.hotwire
            inputs.hotwire.flakeModules.darwinOutputs
            inputs.hotwire.flakeModules.homeManagerOutputs
          ];

          systems = [
            "x86_64-linux"
            "aarch64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
          ];

          hotwire.enable = true;
          hotwire.basePath = moduleLocation;
        }
      );
in
{
  flake.checks = {
    x86_64-darwin.system = exampleFlake.darwinConfigurations.intel.system;
    aarch64-darwin.system = exampleFlake.darwinConfigurations.intel.system;
  };
}
