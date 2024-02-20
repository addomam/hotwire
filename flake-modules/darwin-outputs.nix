/*
Flake.Parts modules for nix-darwin.
*/
{
  lib,
  flake-parts-lib,
  moduleLocation,
  ...
}: {
  options.flake = flake-parts-lib.mkSubmoduleOptions {
    darwinConfigurations = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = {};
      description = ''
        Instantiated Darwin configurations. Used by `darwin-rebuild`.

        `darwinConfigurations` is for specific machines. If you want to expose
        reusable configurations, add them to [`darwinModules`](#opt-flake.darwinModules)
        in the form of modules (no `lib.darwinSystem`), so that you can reference
        them in this or another flake's `darwinConfigurations`.
      '';
      example = lib.literalExpression ''
        {
          my-machine = inputs.darwin.lib.darwinSystem {
            # system = "aarch64-darwin";  # or set nixpkgs.hostPlatform in a module.
            modules = [
              ./my-machine/darwin-configuration.nix
              config.darwinModules.my-module
            ];
          };
        }
      '';
    };

    darwinModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.unspecified;
      default = {};
      apply = lib.mapAttrs (k: v: {
        _file = "${builtins.toString moduleLocation}#darwinModules.${k}";
        imports = [v];
      });
      description = ''
        Darwin modules.

        You may use this for reusable pieces of configuration, service modules, etc.
      '';
    };
  };
}
