{
  networking.hostName = "apple-silicon";
  system.stateVersion = 4;
  nixpkgs.system = "aarch64-darwin";
  test.enable = true;
}
