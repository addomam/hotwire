{
  config,
  lib,
  ...
}: let
  hotwireLib = import ./../../lib.nix {inherit lib;};
in {
  options.hotwire.overlays.enable = lib.mkEnableOption "hotwire overlays";

  config = lib.mkMerge [
    (lib.mkIf config.hotwire.enable {
      hotwire.overlays.enable = lib.mkDefault true;
    })
    (lib.mkIf config.hotwire.overlays.enable {
      flake.overlays =
        builtins.mapAttrs (_: import)
        (hotwireLib.nixFiles (config.hotwire.basePath + "/overlays"));
    })
  ];
}
