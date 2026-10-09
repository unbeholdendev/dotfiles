{ ... }:
{
  imports = [ ./laptop.nix ];

  networking.hostName = "t14";

  disko.devices.disk.main.device = "/dev/nvme0n1";

  boot.initrd.availableKernelModules = [ "thunderbolt" ];

  # The firmware's ACPI errors are KERN_ERR, which 4 prints over the login
  # prompt. A BIOS update does not fix them.
  boot.consoleLogLevel = 3;

  services.fprintd.enable = true;
  # noctalia's lock screen authenticates as login and drives the reader itself;
  # pam_fprintd there would contend for the sensor.
  security.pam.services.login.fprintAuth = false;
}
