{ pkgs, ... }:
{
  home.stateVersion = "26.05";
  news.display = "silent";

  # The whole archive is 222 MiB. LANG must name a locale in this list.
  i18n.glibcLocales = pkgs.glibcLocales.override {
    allLocales = false;
    locales = [
      "C.UTF-8/UTF-8"
      "cs_CZ.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };
}
