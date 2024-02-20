{
  config,
  lib,
  ...
}: let
  hotwireLib = import ./../../lib.nix {inherit lib;};
  cfg = config.hotwire.nixosConfigurations;
in {
  options.hotwire.nixosConfigurations = {
    enable = lib.mkEnableOption "hotwire nixosConfigurations";
    importSelfModules = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "Whether to add `.#nixosModules` to the imports of each configuration.";
    };
    extraModules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = [];
      example = "[homeManager.nixosModule]";
      description = "Additional modules to add to the configurations.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.hotwire.enable {
      hotwire.nixosConfigurations.enable = lib.mkDefault true;
    })
    (lib.mkIf cfg.enable {
      flake.nixosConfigurations = builtins.mapAttrs (_: file:
        lib.nixosSystem {
          modules =
            [file]
            ++ cfg.extraModules
            ++ (
              if cfg.importSelfModules
              then (builtins.attrValues config.flake.nixosModules)
              else []
            );
        })
      (hotwireLib.nixFiles (config.hotwire.basePath + "/nixos-configurations"));
    })
  ];
}
