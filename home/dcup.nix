{ pkgs, ... }:
{
  home.packages = [
    pkgs.jq
    pkgs.qrencode
    pkgs.socat
  ];

  home.file.".local/bin/dcup".source = ../dcup/.local/bin/dcup;
  home.file.".local/bin/dcclaude".source = ../dcup/.local/bin/dcclaude;
  home.file.".local/bin/dccodex".source = ../dcup/.local/bin/dccodex;
  home.file.".local/bin/dcpair".source = ../dcup/.local/bin/dcpair;
}
