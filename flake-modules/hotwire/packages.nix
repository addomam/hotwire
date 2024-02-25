{
  config,
  lib,
  ...
}: let
  hotwireLib = import ./../../lib.nix {inherit lib;};
in {
  options.hotwire.packages.enable = lib.mkEnableOption "hotwire packages";

  config = lib.mkMerge [
    (lib.mkIf config.hotwire.enable {
      hotwire.packages.enable = lib.mkDefault true;
    })
    (lib.mkIf config.hotwire.packages.enable {
      perSystem = {
        pkgs,
        self',
        ...
      }: {
        packages =
          builtins.mapAttrs
          (_name: file: lib.callPackageWith (pkgs // self'.packages) file {})
          (hotwireLib.nixFiles (config.hotwire.basePath + "/packages"));
      };
    })
  ];
}
