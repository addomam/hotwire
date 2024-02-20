# Hotwire

Automatically wire up well-formatted Nix files to flake outputs.

## Description

This repository provies a flake module (for use with [flake.parts](https://flake.parts)). When the corresponding option is enabled (`hotwire.enable = true`), this module will attempt to locate Nix files in your repository relevant to any flake outputs. Depending on the relevant output, the Nix files will be passed to the appropriate function before being added as flake output (e.g. `callPackage` for packages, `nixpkgs.lib.nixosSystem` for NixOS configurations, etc).

## Example `flake.nix`

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hotwire.url = "github:crunchcat/hotwire/master";
    hotwire.inputs.nixpkgs.follows = "nixpkgs";
    flakeParts.url = "github:hercules-ci/flake-parts";
    flakeParts.inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  outputs = inputs @{flakeParts, hotwire, ...}:
    flakeParts.lib.mkFlake {inherit inputs;} {
      imports = [hotwire.flakeModules.hotwire];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      hotwire.enable = true;
    };
}
```

That's all that's requried in the `flake.nix` for this to work. The expected format and locations of the rest of the files are described below.

## Conventions

### Naming

This module was written to follow the [upstream nixpkgs convention](https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md#code-conventions) that file names are `kebab-case` and Nix values are `lowerCamelCase`. If your files follow this convention and are in `kebab-case`, your flake outputs will automatically be converted to `lowerCamelCase`. For example, if you have a package in `packages/my-cool-package.nix` or `packages/my-cool-package/default.nix`, the corresponding flake ouptput will be `.#packages.myCoolPackage`.

### Directory Structure

This module expects to find a directory structure largely resembing the structure of a flake's outputs. For instance, it expects to find files for the `nixosConfigurations` output in the `nixos-configurations` directory. In an output's directory, every file with a `.nix` extension and directory containing a `default.nix` file is expected to correspond to an output. For files or directories that satisfy those conditions, the corresponding output's name will be based on the source's name as described above in [naming](#naming).

For more details on how a specific output is handled, see it's section below.

### Modules Default to Disabled

This module will default to automatically importing all modules into your configurations. As such, you should gate your modules' functionality behind an `enable` option. This ensures all modules can be automatically imported without issue and the desired behavior can be explicitly enabled.

## Flake Options

- `hotwire.enable`

  Defaults to false, meaning the module will do **nothing** when it is only imported. When you set this to true, the module will default to trying to configure all supported outputs. You can disable any of those outputs with the enable option for that output, if you'd like to handle that output manually.

- `hotwire.<output>.enable` (e.g. `hotwire.devShells.enable`)

  Defaults to true if `hotwire.enable` is true. When true will attempt to automatically configure the output.

- `hotwire.<*>Configurations.importSelfModules` (e.g. `hotwire.nixosConfigurations.importSelfModules`)

  Defaults to true. When enabled will add all the modules in the flake's outputs to the `imports` list for every configuration.

- `hotwire.<*>Configurations.extraModules` (e.g. `hotwire.nixosConfigurations.extraModules`)

  A list of additional modules that will be added to the `imports` list for every configuration.

## Outputs

**WARNING: All of this is subject to change.**

Here is an overview of current progress:

|    Implemented     |       Tested       | Output                 | `flake` or `perSystem` | Import Function                                          |
| :----------------: | :----------------: | ---------------------- | ---------------------- | -------------------------------------------------------- |
| :heavy_check_mark: |                    | `apps`                 | `perSystem`            | `file: pkgs.callPackage file {}`                         |
|                    |                    | `checks`               | `perSystem`            |                                                          |
| :heavy_check_mark: |                    | `darwinConfigurations` | `flake`                | `file: lib.darwinSystem {modules = [file];}`             |
| :heavy_check_mark: |                    | `darwinModules`        | `flake`                | `import`                                                 |
| :heavy_check_mark: |                    | `devShells`            | `perSystem`            | `file: pkgs.callPackage file {}`                         |
| :heavy_check_mark: |                    | `flakeModules`         | `flake`                | `import`                                                 |
| :heavy_check_mark: |                    | `formatter`            | `perSystem`            | `file: pkgs.callPackage file {}`                         |
| :heavy_check_mark: |                    | `homeConfigurations`   | `flake`                | `file: lib.homeManagerConfiguration {modules = [file];}` |
| :heavy_check_mark: |                    | `homeModules`          | `flake`                | `import`                                                 |
| :heavy_check_mark: |                    | `lib`                  | `flake`                | `file: import file {inherit lib;}`                       |
|                    |                    | `legacyPackages`       | `perSystem`            |                                                          |
| :heavy_check_mark: |                    | `nixosConfigurations`  | `flake`                | `file: lib.nixosSystem {modules = [file];}`              |
| :heavy_check_mark: |                    | `nixosModules`         | `flake`                | `import`                                                 |
| :heavy_check_mark: |                    | `overlays`             | `flake`                | `import`                                                 |
| :heavy_check_mark: | :heavy_check_mark: | `packages`             | `perSystem`            | `file: pkgs.callPackage file {}`                         |

### `.#apps`

- Looks in the `apps` directory
- Calls files with `callPackage`
  - The flake's `.#pacakges` outputs are available
- I don't have a lot of experience with this output so if you use it and think a better interface would be more useful please reach out

### `.#darwinConfigurations`

- Looks in the `darwin-configurations` directory
- Calls files with nix-darwin's `lib.darwinSystem`
  - Be sure to specify `nixpkgs.localSystem`

### `.#darwinModules`

- Looks in the `darwin-modules` directory
- Expects files to be nix-darwin modules

### `.#devShells`

- Looks in the `dev-shells` directory
- Calls files with `callPackage`
  - The flake's `.#pacakges` outputs are available

### `.#flakeModules` (for use with flake.parts)

- Looks in the `flake-modules` directory
- Expects files to be flake modules for use with flake.parts

### `.#formatter`

- Looks for a file named `formatter.nix` or `formatter/default.nix`
- Calls this file with `callPackage`
  - The flake's `.#pacakges` outputs are available

### `.#homeConfigurations`

- Looks in the `home-configurations` directory
- Calls configurations with Home Manager's `lib.homeManagerConfiguration`
  - Be sure to specify `nixpkgs.localSystem`

### `.#homeModules`

- Looks for modules and configurations in the `home-modules` and `home-configurations` directories respectively
- Expects files to be Home Manager modules

### `.#lib`

- Looks in the `lib` directory
- Expects the files to be a function with one named argument: `lib`
  - This format was chosen since it's simple enough and is the way upstream Nixpkgs lib is structured

### `.#nixosConfigurations`

- Looks in the `nixos-configurations` directory
- Expects the files to be in the same format as `configuration.nix`, i.e. a NixOS module
  - Be sure to specify `nixpkgs.localSystem`
- Calls these files with `nixpkgs.lib.nixosSystem`

### `.#nixosModules`

- Looks in the `nixos-modules` directory
- Expects files to be NixOS modules

### `.#overlays`

- Looks in the `overlays` directory
- Expects files to be overlays

### `.#packages`

- Looks in the `packages` directory
- Calls files with `callPackage`
  - Other packages in the flake's `.#pacakges` outputs are available (be sure not to introduce circular dependencies)
