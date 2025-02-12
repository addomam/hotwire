{ config, lib, ... }:
let
  hotwireLib = import ./../../lib.nix { inherit lib; };
  cfg = config.hotwire.overlays;
in
{
  options.hotwire.overlays = {
    enable = lib.mkEnableOption "hotwire overlays";
    generatePackagesOverlay = lib.mkOption {
      default = true;
      example = false;
      type = lib.types.bool;
      description = "Whether to generate a `.#overlays.packages` that overlays all the packages of this flake. Depends on hotwire.packages.enable being true.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.hotwire.enable { hotwire.overlays.enable = lib.mkDefault true; })
    (lib.mkIf cfg.enable (
      lib.mkMerge [
        {
          flake.overlays = builtins.mapAttrs (_: import) (
            hotwireLib.nixFiles (config.hotwire.basePath + /overlays)
          );
        }
        /*
          For some reason this causes infinite recursion in NixOS configurations but the other implementation doesn't
          (lib.mkIf cfg.generatePackagesOverlay {
            flake.overlays.packages = (_: prev:
              config.flake.packages."${prev.system}"
            );
          })
        */
        (lib.mkIf cfg.generatePackagesOverlay {
          flake.overlays.packages =
            final: _:
            builtins.mapAttrs (_name: file: final.callPackage file { }) (
              hotwireLib.nixFiles (config.hotwire.basePath + /packages)
            );
        })
      ]
    ))
  ];
}
