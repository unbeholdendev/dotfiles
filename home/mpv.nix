{ pkgs, ... }:
{
  programs.mpv = {
    enable = true;

    # Without mpris the bar's media widget and the XF86Audio keys cannot see mpv.
    scripts = [ pkgs.mpvScripts.mpris ];

    config = {
      hwdec = "auto-safe";
      vo = "gpu-next";
    };
  };
}
