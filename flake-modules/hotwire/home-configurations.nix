{
  config,
  lib,
  inputs,
  ...
}: let
  hotwireLib = import ./../../lib.nix {inherit lib;};
  cfg = config.hotwire.homeConfigurations;
in {
  options.hotwire.homeConfigurations = {
    enable = lib.mkEnableOption "hotwire homeConfigurations";
    importSelfModules = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "Whether to add `.#homeModules` to the imports of each configuration.";
    };
    extraModules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = [];
      example = "[impermanence.homeModule]";
      description = "Additional modules to add to the configurations.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.hotwire.enable {
      hotwire.homeConfigurations.enable = lib.mkDefault true;
    })
    (lib.mkIf cfg.enable {
      flake.homeConfigurations = builtins.mapAttrs (_: file:
        inputs.homeManager.lib.homeManagerConfiguration {
          modules =
            [file]
            ++ cfg.extraModules
            ++ (
              if cfg.importSelfModules
              then (builtins.attrValues config.flake.homeModules)
              else []
            );
        })
      (hotwireLib.nixFiles (config.hotwire.basePath + "/home-configurations"));
    })
  ];
}
