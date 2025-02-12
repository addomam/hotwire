{ config, lib, ... }:
{
  options.hotwire.lib.enable = lib.mkEnableOption "hotwire lib";

  config = lib.mkMerge [
    (lib.mkIf config.hotwire.enable { hotwire.lib.enable = lib.mkDefault true; })
    (lib.mkIf config.hotwire.lib.enable {
      flake =
        let
          dirPath = config.hotwire.basePath + /lib;
          filePath = config.hotwire.basePath + /lib.nix;
          libPath =
            if builtins.pathExists dirPath then
              dirPath
            else if builtins.pathExists filePath then
              filePath
            else
              null;
        in
        lib.mkIf (libPath != null) { lib = import libPath { inherit lib; }; };
    })
  ];
}
