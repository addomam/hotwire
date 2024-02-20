{
  config,
  lib,
  ...
}: let
  hotwireLib = import ./../../lib.nix {inherit lib;};
in {
  options.hotwire.devShells.enable = lib.mkEnableOption "hotwire devShells";

  config = lib.mkMerge [
    (lib.mkIf config.hotwire.enable {
      hotwire.devShells.enable = lib.mkDefault true;
    })
    (lib.mkIf config.hotwire.devShells.enable {
      perSystem = {
        pkgs,
        self',
        ...
      }: {
        devShells =
          builtins.mapAttrs
          (_: file: pkgs.callPackage file self'.packages)
          (hotwireLib.nixFiles (config.hotwire.basePath + "/dev-shells"));
      };
    })
  ];
}
