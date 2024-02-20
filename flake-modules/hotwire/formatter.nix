{
  config,
  lib,
  ...
}: {
  options.hotwire.formatter.enable = lib.mkEnableOption "hotwire formatter";

  config = lib.mkMerge [
    (lib.mkIf config.hotwire.enable {
      hotwire.formatter.enable = lib.mkDefault true;
    })
    (lib.mkIf config.hotwire.formatter.enable {
      perSystem = {
        pkgs,
        self',
        ...
      }: let
        dirPath = config.hotwire.basePath + "/formatter";
        filePath = config.hotwire.basePath + "/formatter.nix";
        formatterPath =
          if builtins.pathExists dirPath
          then dirPath
          else if builtins.pathExists filePath
          then filePath
          else null;
      in
        lib.mkIf (formatterPath != null) {
          formatter = pkgs.callPackage formatterPath self'.packages;
        };
    })
  ];
}
