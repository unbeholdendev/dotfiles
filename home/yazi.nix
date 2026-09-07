{ pkgs, ... }:
let
  # gruvbox means its bright row for text on a dark ground, and yazi's preset
  # uses the regular row. Its own blue-on-gray pairs are 1.5:1, so those two
  # take dark text instead.
  block = bg: { inherit bg; fg = "black"; bold = true; };
  tail = { bg = "gray"; fg = "black"; };
in
{
  home.packages = [ pkgs.zathura ];

  programs.yazi = {
    enable = true;

    settings = {
      opener = {
        edit = [
          {
            run = ''nvim "$@"'';
            desc = "nvim";
            block = true;
            for = "unix";
          }
        ];
        pdf = [
          {
            run = ''zathura "$@"'';
            orphan = true;
            desc = "zathura";
          }
        ];
      };

      open.prepend_rules = [
        {
          mime = "application/pdf";
          use = "pdf";
        }
      ];

      mgr.linemode = "full";
    };

    theme.tabs = {
      active = block "lightblue";
      inactive = tail;
    };

    theme.mode = {
      normal_main = block "lightblue";
      normal_alt = tail;
      select_main = block "lightred";
      select_alt = tail;
      unset_main = block "lightred";
      unset_alt = tail;
    };

    theme.status.perm_write.fg = "lightred";

    # A mime rule cannot colour the preview pane, which never resolves mimes.
    theme.filetype.rules = [
      { url = "*.{jpg,jpeg,png,gif,bmp,webp,avif,heic,heif,jxl,svg,ico,tiff}"; fg = "lightyellow"; }
      { url = "*.{mp3,flac,wav,ogg,opus,m4a,aac,mp4,mkv,webm,avi,mov,wmv}"; fg = "lightmagenta"; }
      { url = "*.{zip,rar,7z,tar,gz,tgz,xz,zst,bz2,lzma,cpio,arj,xar,cab}"; fg = "lightred"; }
      { url = "*.{pdf,doc,docx,rtf,odt,epub}"; fg = "lightcyan"; }
      { mime = "**/image/*"; fg = "lightyellow"; }
      { mime = "**/{audio,video}/*"; fg = "lightmagenta"; }
      { mime = "**/application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}"; fg = "lightred"; }
      { mime = "**/application/{pdf,doc,rtf}"; fg = "lightcyan"; }
      { mime = "vfs/{absent,stale}"; fg = "darkgray"; }
      { url = "*"; is = "orphan"; bg = "red"; }
      { url = "*"; is = "exec"; fg = "lightgreen"; }
      { url = "*"; is = "dummy"; bg = "red"; }
      { url = "*/"; is = "dummy"; bg = "red"; }
      { url = "*/"; fg = "lightblue"; }
    ];

    keymap.mgr.prepend_keymap = [
      {
        on = "<Enter>";
        run = "plugin smart-enter";
        desc = "Enter the child directory, or open the file";
      }
    ];

    initLua = ../yazi/.config/yazi/init.lua;

    plugins."smart-enter" = ../yazi/.config/yazi/plugins/smart-enter.yazi;
  };
}
