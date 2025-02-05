{
  networking.hostName = "intel";
  system.stateVersion = 4;
  nixpkgs.hostPlatform.system = "x86_64-darwin";
  test.enable = true;
}
