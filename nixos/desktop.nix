{ noctalia, pkgs, ... }:
{
  programs.niri.enable = true;

  environment.systemPackages = [ noctalia ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
}
