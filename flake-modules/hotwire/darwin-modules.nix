{
  config,
  lib,
  ...
}: let
  hotwireLib = import ./../../lib.nix {inherit lib;};
in {
  options.hotwire.darwinModules.enable = lib.mkEnableOption "hotwire darwinModules";

  config = lib.mkMerge [
    (lib.mkIf config.hotwire.enable {
      hotwire.darwinModules.enable = lib.mkDefault true;
    })
    (lib.mkIf config.hotwire.darwinModules.enable {
      flake.darwinModules =
        hotwireLib.nixFiles (config.hotwire.basePath + "/darwin-modules");
    })
  ];
}
