{
  config,
  lib,
  moduleLocation,
  ...
}:

let
  mkFlakeAttrs =
    {
      output,
      description ? output,
      dirname ? output,
      namespace ? "hotwire",
      defaultFile ? "default.nix",
      preprocess ?
        _args: _name: path:
        path,
    }:
    {
      lib,
      config,
      options,
      ...
    }@args:
    let
      cfg = config.${namespace}.${output};
    in
    {
      options.${namespace}.${output} = {
        enable = lib.mkEnableOption "hotwire ${description} to ${output} flake output";

        path = lib.mkOption {
          type = lib.types.pathInStore;
          default = config.hotwire.basePath + "/${dirname}";
        };

        preprocess = lib.mkOption {
          type = lib.types.functionTo (
            lib.types.functionTo (lib.types.functionTo options.flake.${output}.type)
          );
          default = preprocess;
        };
      };

      config = lib.mkIf (cfg.enable && (builtins.pathExists cfg.path)) {
        flake.${output} = lib.pipe cfg.path [
          builtins.readDir
          (lib.attrsets.mapAttrs' (
            name: type:
            # Accept regular files that have a .nix file extension
            if (type == "regular" && lib.strings.hasSuffix ".nix" name) then
              lib.attrsets.nameValuePair (lib.strings.removeSuffix ".nix" name) (cfg.path + "/${name}")
            else if # Accept directories that contain a ${defaultFile}
              (type == "directory" && builtins.fileExists (cfg.path + "/${name}/${defaultFile}"))
            then
              lib.attrsets.nameValuePair name (cfg.path + "/${name}/${defaultFile}")
            # Otherwise set to null so we can filter it out in the next step
            else
              lib.attrsets.nameValuePair name null
          ))
          (lib.attrsets.filterAttrs (_: v: v != null))
          (builtins.mapAttrs (cfg.preprocess args))
        ];
      };
    };

  mkPerSystemAttrs =
    {
      output,
      description ? output,
      defaultFile ? "default.nix",
      dirname ? output,
      namespace ? "hotwire",
      preprocess ?
        _args: _name: path:
        path,
    }:
    {
      config,
      lib,
      options,
      ...
    }:
    let
      cfg = config.${namespace}.${output};
    in
    {
      options.${namespace}.${output} = {
        enable = lib.mkEnableOption "hotwire ${description} to ${output} flake output";

        path = lib.mkOption {
          type = lib.types.pathInStore;
          default = config.hotwire.basePath + "/${dirname}";
        };

        preprocess = lib.mkOption {
          type = lib.types.functionTo (lib.types.functionTo (lib.types.functionTo lib.types.anything));
          default = preprocess;
        };
      };

      config = lib.mkIf (cfg.enable && (builtins.pathExists cfg.path)) {
        perSystem = args: {
          ${output} = lib.pipe cfg.path [
            builtins.readDir
            (lib.attrsets.mapAttrs' (
              name: type:
              # Accept regular files that have a .nix file extension
              if (type == "regular" && lib.strings.hasSuffix ".nix" name) then
                lib.attrsets.nameValuePair (lib.strings.removeSuffix ".nix" name) (cfg.path + "/${name}")
              else if # Accept directories that contain a ${defaultFile}
                (type == "directory" && builtins.fileExists (cfg.path + "/${name}/${defaultFile}"))
              then
                lib.attrsets.nameValuePair name (cfg.path + "/${name}/${defaultFile}")
              # Otherwise set to null so we can filter it out in the next step
              else
                lib.attrsets.nameValuePair name null
            ))
            (lib.attrsets.filterAttrs (_: v: v != null))
            (builtins.mapAttrs (cfg.preprocess args))
          ];
        };
      };
    };

  mkPerSystemSingleton =
    {
      output,
      description ? output,
      defaultFile ? "default.nix",
      dirname ? output,
      namespace ? "hotwire",
      preprocess ?
        _args: _name: path:
        path,
    }:
    {
      config,
      lib,
      options,
      ...
    }:
    let
      cfg = config.${namespace}.${output};
    in
    {
      options.${namespace}.${output} = {
        enable = lib.mkEnableOption "hotwire ${description} to ${output} flake output";

        path = lib.mkOption {
          type = lib.types.str;
          default = "${config.hotwire.basePath}/${dirname}";
        };

        preprocess = lib.mkOption {
          type = lib.types.functionTo (lib.types.functionTo (lib.types.functionTo lib.types.anything));
          default = preprocess;
        };
      };

      config = lib.mkIf cfg.enable {
        perSystem = args: {
          ${output} = lib.mkMerge [
            (lib.mkIf (builtins.pathExists "${cfg.path}.nix") (
              cfg.preprocess args cfg.output (cfg.path + ".nix")
            ))

            (lib.mkIf (builtins.pathExists cfg.path) (
              lib.mkIf (builtins.pathExists "${cfg.path}/${defaultFile}") (
                cfg.preprocess args output (cfg.path + "/${defaultFile}")
              )
            ))
          ];
        };
      };
    };
in

{
  imports =
    (builtins.map mkFlakeAttrs [
      {
        output = "darwinConfigurations";
        preprocess =
          { inputs, self, ... }:
          _: path:
          inputs.darwin.lib.darwinSystem {
            modules = [ path ];
            specialArgs.flake = self;
          };
      }
      { output = "darwinModules"; }
      { output = "flakeModules"; }
      {
        output = "homeConfigurations";
        preprocess =
          { inputs, self, ... }:
          _: path:
          inputs.homeManagerConfiguration {
            modules = [ path ];
            specialArgs.flake = self;
          };
      }
      { output = "homeModules"; }
      {
        output = "nixosConfigurations";
        preprocess =
          { inputs, self, ... }:
          _: path:
          inputs.nixpkgs.lib.nixosSystem {
            modules = [ path ];
            specialArgs.flake = self;
          };
      }
      { output = "nixosModules"; }
      {
        output = "overlays";
        preprocess = _: _: import;
      }
    ])
    ++ (builtins.map mkPerSystemAttrs [
      {
        output = "apps";
        preprocess =
          {
            pkgs,
            self',
            lib,
            ...
          }:
          _: path: lib.callPackageWith (pkgs // self'.packages) path { };
      }
      {
        output = "devShells";
        preprocess =
          {
            pkgs,
            self',
            lib,
            ...
          }:
          _: path: lib.callPackageWith (pkgs // self'.packages) path { };
      }
      {
        output = "packages";
        preprocess =
          {
            pkgs,
            self',
            lib,
            ...
          }:
          _: path: lib.callPackageWith (pkgs // self'.packages) path { };
      }
    ])
    ++ (builtins.map mkPerSystemSingleton [
      {
        output = "formatter";
        preprocess =
          {
            pkgs,
            self',
            lib,
            ...
          }:
          _: path: lib.callPackageWith (pkgs // self'.packages) path { };
      }
      {
        output = "lib";
        preprocess = { lib, ... }: _: path: import path { inherit lib; };
      }
    ]);

  options = {
    hotwire = {
      enable = lib.mkEnableOption "Hotwire, the convention over configuration flake module";

      basePath = lib.mkOption {
        type = lib.types.pathInStore;
        default = moduleLocation;
        description = "The absolute base path to the nix files";
      };
    };
  };

  config = lib.mkIf config.hotwire.enable {
    hotwire =
      lib.attrsets.genAttrs
        [
          "apps"
          "darwinConfigurations"
          "darwinModules"
          "devShells"
          "flakeModules"
          "formatter"
          #"homeConfigurations" disabled until you can set system in a module
          "homeModules"
          "lib"
          "nixosConfigurations"
          "nixosModules"
          "overlays"
          "packages"
        ]
        (_: {
          enable = true;
        });
  };
}
