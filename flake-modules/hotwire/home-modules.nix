{
  config,
  lib,
  ...
}: let
  hotwireLib = import ./../../lib.nix {inherit lib;};
in {
  options.hotwire.homeModules.enable = lib.mkEnableOption "hotwire homeModules";

  config = lib.mkMerge [
    (lib.mkIf config.hotwire.enable {
      hotwire.homeModules.enable = lib.mkDefault true;
    })
    (lib.mkIf config.hotwire.homeModules.enable {
      flake.homeModules =
        hotwireLib.nixFiles (config.hotwire.basePath + "/home-modules");
    })
  ];
}
