{
  networking.hostName = "arm";
  nixpkgs.system = "aarch64-linux";
  fileSystems."/".fsType = "tmpfs";
  boot.loader.systemd-boot.enable = true;
  test.enable = true;
}
