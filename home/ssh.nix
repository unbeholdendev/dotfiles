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
      # Cloudflare proxies this name and drops port 222, so ssh hangs on it.




    };
  };
}
