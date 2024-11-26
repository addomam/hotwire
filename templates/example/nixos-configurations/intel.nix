{
  networking.hostName = "intel";
  nixpkgs.system = "x86_64-linux";
  fileSystems."/".fsType = "tmpfs";
  boot.loader.systemd-boot.enable = true;
  test.enable = true;
}
