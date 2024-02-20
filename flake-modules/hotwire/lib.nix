{
  config,
  lib,
  ...
}: let
  hotwireLib = import ./../../lib.nix {inherit lib;};
in {
  options.hotwire.lib.enable = lib.mkEnableOption "hotwire lib";

  config = lib.mkMerge [
    (lib.mkIf config.hotwire.enable {
      hotwire.lib.enable = lib.mkDefault true;
    })
    (lib.mkIf config.hotwire.lib.enable {
      flake.lib =
        builtins.mapAttrs
        (_: file: import file {inherit lib;})
        (hotwireLib.nixFiles (config.hotwire.basePath + "/lib"));
    })
  ];
}
