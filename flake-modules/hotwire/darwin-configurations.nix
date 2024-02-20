{
  config,
  lib,
  inputs,
  ...
}: let
  hotwireLib = import ./../../lib.nix {inherit lib;};
  cfg = config.hotwire.darwinConfigurations;
in {
  options.hotwire.darwinConfigurations = {
    enable = lib.mkEnableOption "hotwire darwinConfigurations";
    importSelfModules = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "Whether to add `.#darwinModules` to the imports of each configuration.";
    };
    extraModules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = [];
      example = "[homeManager.darwinModule]";
      description = "Additional modules to add to the configurations.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.hotwire.enable {
      hotwire.darwinConfigurations.enable = lib.mkDefault true;
    })
    (lib.mkIf cfg.enable {
      flake.darwinConfigurations = builtins.mapAttrs (_: file:
        inputs.darwin.lib.darwinSystem {
          modules =
            [file]
            ++ cfg.extraModules
            ++ (
              if cfg.importSelfModules
              then (builtins.attrValues config.flake.darwinModules)
              else []
            );
        })
      (hotwireLib.nixFiles (config.hotwire.basePath + "/darwin-configurations"));
    })
  ];
}
