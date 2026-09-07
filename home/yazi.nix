{ pkgs, ... }:
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

    # A mime rule cannot colour the preview pane, which never resolves mimes.
    theme.filetype.rules = [
      { url = "*.{jpg,jpeg,png,gif,bmp,webp,avif,heic,heif,jxl,svg,ico,tiff}"; fg = "yellow"; }
      { url = "*.{mp3,flac,wav,ogg,opus,m4a,aac,mp4,mkv,webm,avi,mov,wmv}"; fg = "magenta"; }
      { url = "*.{zip,rar,7z,tar,gz,tgz,xz,zst,bz2,lzma,cpio,arj,xar,cab}"; fg = "red"; }
      { url = "*.{pdf,doc,docx,rtf,odt,epub}"; fg = "cyan"; }
      { mime = "**/image/*"; fg = "yellow"; }
      { mime = "**/{audio,video}/*"; fg = "magenta"; }
      { mime = "**/application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}"; fg = "red"; }
      { mime = "**/application/{pdf,doc,rtf}"; fg = "cyan"; }
      { mime = "vfs/{absent,stale}"; fg = "darkgray"; }
      { url = "*"; is = "orphan"; bg = "red"; }
      { url = "*"; is = "exec"; fg = "green"; }
      { url = "*"; is = "dummy"; bg = "red"; }
      { url = "*/"; is = "dummy"; bg = "red"; }
      { url = "*/"; fg = "blue"; }
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
