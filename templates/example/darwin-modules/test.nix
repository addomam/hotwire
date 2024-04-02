{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.test.enable = lib.mkEnableOption "test module";
  config = lib.mkIf config.test.enable {
    # Make sure the flake's local packages are available
    environment.systemPackages = [ pkgs.dependency ];
  };
}
