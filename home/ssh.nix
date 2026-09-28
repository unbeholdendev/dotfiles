{ ... }:
let
  identity = {
    IdentityFile = "~/.ssh/id_ed25519";
    IdentitiesOnly = true;
  };
in
{
  programs.ssh = {
    enable = true;

    # The file this replaces has no `Host *` block.
    enableDefaultConfig = false;

    settings = builtins.mapAttrs (_: block: identity // block) {
      "git.unbeholden.dev" = { User = "git"; Port = 222; };




    }
    // {
      "*" = {
        ServerAliveInterval = 15;
        ServerAliveCountMax = 3;
      };
    };
  };
}
