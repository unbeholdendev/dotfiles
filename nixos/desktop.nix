{ pkgs, ... }:
{
  programs.niri.enable = true;

  programs.gpu-screen-recorder.enable = true;

  # qt6ct answers to qt5ct too, the one name this option offers.
  qt = {
    enable = true;
    platformTheme = "qt5ct";
  };

  environment.systemPackages = with pkgs; [
    noctalia
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
