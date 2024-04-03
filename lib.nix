# Helper functions for Hotwire
{ lib }:
rec {
  /*
    Make the first character in a string upper-case and the rest of the string
    lower-case.

    Type: capitalize :: string -> string

    Example:
      capitalize "washINGton"
      => "Washington"
  */
  capitalize =
    string:
    lib.strings.concatImapStrings (
      i: char: if i == 1 then lib.strings.toUpper char else lib.strings.toLower char
    ) (builtins.elemAt (builtins.split "(.)(.*)" string) 1);

  /*
    Makes a kebab-case string camel-case.

    Type: kebabToCamel :: string -> string

    Example:
      kebabToCamel "kebabs-turn-to-camels"
      => "kebabsTurnToCamels"
  */
  kebabToCamel =
    kebab:
    lib.strings.concatImapStrings (i: s: if i == 1 then lib.strings.toLower s else capitalize s) (
      lib.strings.splitString "-" kebab
    );

  /*
    Makes a camel-case string kebab-case.

    Type: camelToKebab :: string -> string

    Example:
      camelToKebab "camelsTurnToKebabs"
      => "camels-turn-to-kebabs"
  */
  camelToKebab =
    camel:
    lib.strings.toLower (
      builtins.concatStringsSep "-" (
        builtins.concatLists (
          builtins.filter (x: !(builtins.isString x)) (builtins.split "(.[^A-Z]*)" camel)
        )
      )
    );

  /*
    Returns an attrset containing all the Nix files in a directory. If a file
    has a ".nix" extension it is assumed to be a Nix file. Any directories are
    included if they contain a file named "default.nix". The attrset's names
    are derived from the file names but converted from kebab-case to
    camel-case.

    Type: nixFiles :: path -> attrsOf path

    Example:
      nixFiles "./path/to/directory"
      => {
        file = ./path/to/directory/file.nix;
        directory = ./path/to/directory/directory/default.nix;
      }
  */
  nixFiles =
    directory:
    if !builtins.pathExists directory then
      { }
    else
      lib.attrsets.mapAttrs'
        (fileName: lib.attrsets.nameValuePair (kebabToCamel (lib.strings.removeSuffix ".nix" fileName)))
        (
          lib.attrsets.filterAttrs (_: builtins.pathExists) (
            lib.attrsets.filterAttrs (_: filePath: lib.strings.hasSuffix ".nix" (builtins.toString filePath)) (
              builtins.mapAttrs (
                fileName: fileType:
                if fileType == "directory" then
                  directory + "/${fileName}/default.nix"
                else
                  directory + "/${fileName}"
              ) (builtins.readDir directory)
            )
          )
        );

  /*
    Recursively merges an attribute from a list of attrsets.

    Type: recursiveUpdateAttr :: listOf attrsOf attrsOf any -> attrsOf any

    Example:
      recursiveUpdateAttr "foo" [{bar.a = 1;} {bar.b = 2;} {bar.c = 3;}]
      => { a = 1; b = 2; c = 3; }
  */
  recursiveUpdateAttr =
    attr: attrsets:
    lib.lists.foldl lib.attrsets.recursiveUpdate { } (
      builtins.map (attrset: attrset."${attr}") (builtins.filter (attrset: attrset ? "${attr}") attrsets)
    );

  /*
    Filter the inputs variable to remove self and any inputs not containing an
    attr output and then return a list of their attr outputs.

    Type: filterInputsForAttr :: string -> attrsOf attrsOf any -> listOf any

    Exaample:
      filterInputsForAttr "lib" inputs
      => [{...} {...}]
  */
  filterInputsForAttr =
    attr: inputs:
    lib.attrsets.mapAttrsToList (_: builtins.getAttr attr) (
      lib.attrsets.filterAttrs (
        name: input:
        name != "self" # filter out self to avoid infinite recursion
        && input ? "${attr}" # filter out any inputs that don't output attr
      ) inputs
    );

  /*
    Make a lib from all flake inputs.

    Type: mkLib :: attrset -> directory -> attrset

    Example:
      mkLib inputs ./lib
      => {...}
  */
  mkLib =
    {
      inputs ? null,
      libDir ? null,
    }:
    let
      inputsLib =
        if inputs == null then
          { }
        else
          lib.lists.foldl lib.attrsets.recursiveUpdate { } (filterInputsForAttr "lib" inputs);

      flakeLib =
        if libDir == null then
          { }
        else
          builtins.mapAttrs (_: file: import file { lib = inputsLib; }) (nixFiles libDir);
    in
    lib.attrsets.recursiveUpdate inputsLib flakeLib;

  # Overload flake-parts' mkFlake with the Lib from this flake and all inputs.
  mkFlake =
    args@{
      inputs,
      libDir ? null,
      flakeModulesDir ? null,
      importFlakeInputModules ? true,
      ...
    }:
    let
      lib = mkLib { inherit inputs libDir; };
      # Filter out custom arguments so we don't pass unexpected arguments to the
      # real mkFlake
      filteredArgs = lib.attrsets.filterAttrs (
        name: _:
        !builtins.elem name [
          "libDir"
          "flakeModulesDir"
          "importFlakeInputModules"
        ]
      ) args;
    in
    module:
    lib.mkFlake (lib.attrsets.recursiveUpdate filteredArgs { specialArgs.lib = lib; }) {
      imports =
        [ module ]
        ++ (if flakeModulesDir != null then builtins.attrValues (nixFiles flakeModulesDir) else [ ])
        ++ (
          if
            importFlakeInputModules # This is difficult to implement since flake-parts outputs shit modules
          then
            [ ]
          else
            [ ]
        );
    };
}
