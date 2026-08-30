{ ... }:
{
  home.file.".devcontainers/bin/dcup" = {
    source = ../dcup/.devcontainers/bin/dcup;
    executable = true;
  };

  home.file.".devcontainers/bin/dcclaude" = {
    source = ../dcup/.devcontainers/bin/dcclaude;
    executable = true;
  };
}
