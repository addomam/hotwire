{ lib, self, ... }:
{
  imports = [
    ./apps.nix
    ./darwin-configurations.nix
    ./darwin-modules.nix
    ./dev-shells.nix
    ./flake-modules.nix
    ./formatter.nix
    ./home-configurations.nix
    ./home-modules.nix
    ./lib.nix
    ./nixos-configurations.nix
    ./nixos-modules.nix
    ./overlays.nix
    ./packages.nix
  ];

  options.hotwire = {
    enable = lib.mkEnableOption "Hotwire, the convention over configuration flake module";

    basePath = lib.mkOption {
      type = lib.types.pathInStore;
      default = self.outPath;
      description = "The absolute base path to the nix files";
    };
  };
}
