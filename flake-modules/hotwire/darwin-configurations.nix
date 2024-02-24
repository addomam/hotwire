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
    overlaySelfPackages = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "Whether to add an overlay to the configuration's nixpkgs that includes `.#packages`. Depends on `.#overlays.packages`.";
    };
    globalModules = lib.mkOption {
      description = "The collection of modules to include in every configuration.";
      type = lib.types.listOf lib.types.deferredModule;
      default = [];
      internal = true;
      visible = false;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.hotwire.enable {
      hotwire.darwinConfigurations.enable = lib.mkDefault true;
    })
    (lib.mkIf cfg.enable {
      hotwire.darwinConfigurations.globalModules = lib.mkMerge [
        cfg.extraModules
        (lib.mkIf cfg.importSelfModules (builtins.attrValues config.flake.darwinModules))
        (lib.mkIf cfg.overlaySelfPackages ([{nixpkgs.overlays = [config.flake.overlays.packages];}]))
      ];

      flake.darwinConfigurations = builtins.mapAttrs (_: file:
        inputs.darwin.lib.darwinSystem {
          modules = [file] ++ cfg.globalModules;
        })
      (hotwireLib.nixFiles (config.hotwire.basePath + "/darwin-configurations"));
    })
  ];
}
