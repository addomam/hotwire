{
  inputs = {
    hotwire.url = "github:addomam/hotwire";

    flakeParts.follows = "hotwire/flakeParts";
    nixpkgs.follows = "hotwire/nixpkgs";
  };

  outputs = inputs @ {
    flakeParts,
    hotwire,
    ...
  }:
    flakeParts.lib.mkFlake {inherit inputs;} {
      imports = [hotwire.flakeModules.hotwire];
      systems = ["x86_64-linux"];
      hotwire.enable = true;
    };
}
