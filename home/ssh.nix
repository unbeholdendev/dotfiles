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

    # The file this replaces has no `Host *` block, so the defaults this option
    # adds would be new behaviour rather than the same behaviour in Nix.
    enableDefaultConfig = false;

    settings = builtins.mapAttrs (_: block: identity // block) {
      # Cloudflare proxies this name and carries web ports alone, so port 222
      # to the name is dropped and ssh hangs. The address answers on the LAN
      # and through pangolin from away.




    };
  };
}
