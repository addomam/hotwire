{
  config,
  lib,
  ...
}: let
  hotwireLib = import ./../../lib.nix {inherit lib;};
in {
  options.hotwire.apps.enable = lib.mkEnableOption "hotwire apps";

  config = lib.mkMerge [
    (lib.mkIf config.hotwire.enable {
      hotwire.apps.enable = lib.mkDefault true;
    })
    (lib.mkIf config.hotwire.apps.enable {
      perSystem = {
        pkgs,
        self',
        ...
      }: {
        apps =
          builtins.mapAttrs
          (_: file: pkgs.callPackage file self'.packages)
          (hotwireLib.nixFiles (config.hotwire.basePath + "/apps"));
      };
    })
  ];
}
