{ ... }:
{
  home.file.".local/bin/dcup" = {
    source = ../dcup/.local/bin/dcup;
    executable = true;
  };

  home.file.".local/bin/dcclaude" = {
    source = ../dcup/.local/bin/dcclaude;
    executable = true;
  };
}
