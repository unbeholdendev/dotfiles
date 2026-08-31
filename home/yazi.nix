{ ... }:
{
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
