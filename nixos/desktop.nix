{ pkgs, ... }:
{
  programs.niri.enable = true;

  programs.gpu-screen-recorder.enable = true;

  environment.systemPackages = with pkgs; [
    noctalia
    qt6Packages.qt6ct
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };

  # qt.enable would set this too, but its qt5ct theme brings in Qt 5.
  environment.profileRelativeSessionVariables.QT_PLUGIN_PATH =
    [ "/${pkgs.qt6.qtbase.qtPluginPrefix}" ];

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
