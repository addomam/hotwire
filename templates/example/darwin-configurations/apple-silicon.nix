{
  networking.hostName = "appleSilicon";
  system.stateVersion = 4;
  nixpkgs.hostPlatform.system = "aarch64-darwin";
  test.enable = true;
}
