{ ... }:
{
  imports = [ ./laptop.nix ];

  networking.hostName = "t460s";

  disko.devices.disk.main.device = "/dev/sda";
}
