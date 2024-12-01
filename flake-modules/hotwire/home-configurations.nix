{
  config,
  lib,
  inputs,
  ...
}:
let
  hotwireLib = import ./../../lib.nix { inherit lib; };
  cfg = config.hotwire.homeConfigurations;
in
{
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
      default = [ ];
      example = "[impermanence.homeModule]";
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
    # Disabling by default until Home Manager either has a nixpkgs.hostSystem
    # option or until someone figures out how to set `pkgs` in a general way.
    #(lib.mkIf config.hotwire.enable { hotwire.homeConfigurations.enable = lib.mkDefault true; })
    (lib.mkIf cfg.enable {
      hotwire.homeConfigurations.globalModules = lib.mkMerge [
        cfg.extraModules
        (lib.mkIf cfg.importSelfModules (builtins.attrValues config.flake.homeModules))
        (lib.mkIf cfg.overlaySelfPackages [ { nixpkgs.overlays = [ config.flake.overlays.packages ]; } ])
      ];

      flake.homeConfigurations = builtins.mapAttrs (
        _: file:
        inputs.homeManager.lib.homeManagerConfiguration { modules = [ file ] ++ cfg.globalModules; }
      ) (hotwireLib.nixFiles (config.hotwire.basePath + "/home-configurations"));
    })
  ];
}
