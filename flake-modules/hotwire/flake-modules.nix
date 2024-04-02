{ config, lib, ... }:
let
  hotwireLib = import ./../../lib.nix { inherit lib; };
in
{
  options.hotwire.flakeModules.enable = lib.mkEnableOption "hotwire flakeModules";

  config = lib.mkMerge [
    (lib.mkIf config.hotwire.enable { hotwire.flakeModules.enable = lib.mkDefault true; })
    (lib.mkIf config.hotwire.flakeModules.enable {
      flake.flakeModules = hotwireLib.nixFiles (config.hotwire.basePath + "/flake-modules");
    })
  ];
}
