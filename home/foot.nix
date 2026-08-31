{ config, dotfiles, ... }:
{
  programs.foot = {
    enable = true;

    settings = {
      main = {
        include = "~/.config/foot/themes/noctalia";
        font = "JetBrains Mono:size=11";
        selection-target = "both";
      };

      key-bindings = {
        clipboard-paste = "Control+v Control+Shift+v XF86Paste";
      };
    };
  };

  xdg.configFile."foot/themes/noctalia".source =
    config.lib.file.mkOutOfStoreSymlink
      "${dotfiles}/foot/.config/foot/themes/noctalia";
}
