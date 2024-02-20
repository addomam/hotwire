{
  config,
  lib,
  ...
}: let
  hotwireLib = import ./../../lib.nix {inherit lib;};
in {
  options.hotwire.nixosModules.enable = lib.mkEnableOption "hotwire nixosModules";

  config = lib.mkMerge [
    (lib.mkIf config.hotwire.enable {
      hotwire.nixosModules.enable = lib.mkDefault true;
    })
    (lib.mkIf config.hotwire.nixosModules.enable {
      flake.nixosModules =
        builtins.mapAttrs (_: import)
        (hotwireLib.nixFiles (config.hotwire.basePath + "/nixos-modules"));
    })
  ];
}
