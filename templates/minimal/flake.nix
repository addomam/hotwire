{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    hotwire.url = "github:addomam/hotwire";
    hotwire.inputs.nixpkgs.follows = "nixpkgs";

    flakeParts.follows = "hotwire/flakeParts";
  };

  outputs =
    inputs@{ flakeParts, hotwire, ... }:
    flakeParts.lib.mkFlake { inherit inputs; } {
      imports = [ hotwire.flakeModules.hotwire ];
      systems = [ "x86_64-linux" ];
      hotwire.enable = true;
      hotwire.basePath = ./.;
    };
}
