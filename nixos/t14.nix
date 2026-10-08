{ ... }:
{
  imports = [ ./laptop.nix ];

  networking.hostName = "t14";

  disko.devices.disk.main.device = "/dev/nvme0n1";

  boot.initrd.availableKernelModules = [ "thunderbolt" ];
}
