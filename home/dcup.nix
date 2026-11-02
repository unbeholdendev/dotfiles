{ pkgs, ... }:
{
  home.packages = [
    pkgs.jq
    pkgs.qrencode
    pkgs.socat
  ];

  home.file.".local/bin/dcup".source = ../dcup/.local/bin/dcup;
  home.file.".local/bin/dcpair".source = ../dcup/.local/bin/dcpair;
}
