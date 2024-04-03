{ config, lib, ... }:
let
  hotwireLib = import ./../../lib.nix { inherit lib; };
  cfg = config.hotwire.nixosConfigurations;
in
{
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
      default = [ ];
      example = "[homeManager.nixosModule]";
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
      default = [ ];
      internal = true;
      visible = false;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.hotwire.enable { hotwire.nixosConfigurations.enable = lib.mkDefault true; })
    (lib.mkIf cfg.enable {
      hotwire.nixosConfigurations.globalModules = lib.mkMerge [
        cfg.extraModules
        (lib.mkIf cfg.importSelfModules (builtins.attrValues config.flake.nixosModules))
        (lib.mkIf cfg.overlaySelfPackages [ { nixpkgs.overlays = [ config.flake.overlays.packages ]; } ])
      ];

      flake.nixosConfigurations = builtins.mapAttrs (
        _: file: lib.nixosSystem { modules = [ file ] ++ cfg.globalModules; }
      ) (hotwireLib.nixFiles (config.hotwire.basePath + "/nixos-configurations"));
    })
  ];
}
