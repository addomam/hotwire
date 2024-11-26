{
  inputs,
  self,
  lib,
  ...
}:
let
  availableInputs = inputs // {
    hotwire = self;
  };
  mkFlake =
    path:
    let
      flake = import path;
      flakeInputs = builtins.mapAttrs (name: _: availableInputs."${name}") flake.inputs;
      flakeOutputs = flake.outputs (flakeInputs // { self = flakeOutputs; });
    in
    flakeOutputs;
in
{
  flake.checks = lib.pipe ./templates [
    builtins.readDir # -> { fileName = fileType; }
    (lib.attrsets.filterAttrs (_: type: type == "directory")) # -> { templateName = "directory"; }
    (lib.attrsets.mapAttrs (template: _: mkFlake ./templates/${template}/flake.nix)) # -> { templateName = templateFlake; }
    (lib.attrsets.mapAttrs (_: flake: flake.checks)) # -> { templateName = templateFlake.checks; }
    (lib.attrsets.mapAttrsToList (templateName: checks: { inherit templateName checks; })) # -> [{ templateName; checks = flakeChecks; }]
    (lib.lists.concatMap (
      { templateName, checks }:
      lib.attrsets.mapAttrsToList (system: systemChecks: {
        inherit templateName system systemChecks;
      }) checks
    )) # -> [{ templateName; system; systemChecks = {checkName = check;}; }]
    (lib.lists.concatMap (
      {
        templateName,
        system,
        systemChecks,
      }:
      lib.attrsets.mapAttrsToList (checkName: check: {
        inherit
          templateName
          system
          checkName
          check
          ;
      }) systemChecks
    )) # -> [{templateName; system; checkName; check;}]
    (builtins.map (
      {
        templateName,
        system,
        checkName,
        check,
      }:
      {
        "${system}" = {
          "template-${templateName}_${checkName}" = check;
        };
      }
    )) # -> [{system = {template-${templateName}_${checkName} = check;};}]
    (builtins.foldl' lib.attrsets.recursiveUpdate { }) # -> {system = {template-${templateName}_${checkName} = check;};}
  ];
}
