# Flake.Parts modules for Home Manager
{
  lib,
  flake-parts-lib,
  moduleLocation,
  ...
}:
{
  options.flake = flake-parts-lib.mkSubmoduleOptions {
    homeConfigurations = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
      description = ''
        Instantiated Home Manager configurations. Used by `home-manager`.

        `homeConfigurations` is for specific machines. If you want to expose
        reusable configurations, add them to [`homeModules`](#opt-flake.homeModules)
        in the form of modules (no `lib.homeManagerConfiguration`), so that you can reference
        them in this or another flake's `homeConfigurations`.
      '';
      example = lib.literalExpression ''
        {
          my-machine = inputs.homeManager.lib.homeSystem {
            # system = "aarch64-darwin";  # or set nixpkgs.hostPlatform in a module.
            modules = [
              ./my-machine/home-configuration.nix
              config.homeModules.my-module
            ];
          };
        }
      '';
    };

    homeModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.unspecified;
      default = { };
      apply = lib.mapAttrs (
        k: v: {
          _file = "${builtins.toString moduleLocation}#homeModules.${k}";
          imports = [ v ];
        }
      );
      description = ''
        Home Manager modules.

        You may use this for reusable pieces of configuration, service modules, etc.
      '';
    };
  };
}
