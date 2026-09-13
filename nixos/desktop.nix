{ pkgs, ... }:
{
  programs.niri.enable = true;

  programs.gpu-screen-recorder.enable = true;

  environment.systemPackages = with pkgs; [
    noctalia
    xwayland-satellite
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
  ];

  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Noto Sans" ];
    serif = [ "Noto Serif" ];
  };
}
