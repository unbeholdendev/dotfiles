{ config, ... }:
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

  # noctalia renders this theme, and the store cannot hold a file that is
  # written, so it stays a link out of the store and in the clone.
  xdg.configFile."foot/themes/noctalia".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/Documents/dotfiles/foot/.config/foot/themes/noctalia";
}
