{ ... }:
let
  identity = {
    identityFile = "~/.ssh/id_ed25519";
    identitiesOnly = true;
  };
in
{
  programs.ssh = {
    enable = true;

    # The file this replaces has no `Host *` block, so the defaults this option
    # adds would be new behaviour rather than the same behaviour in Nix.
    enableDefaultConfig = false;

    matchBlocks = builtins.mapAttrs (_: block: identity // block) {
      # Cloudflare proxies this name and carries web ports alone, so port 222
      # to the name is dropped and ssh hangs. The address answers on the LAN
      # and through pangolin from away.
      "git.home.unbeholden.dev" = { hostname = "192.0.2.10"; user = "git"; port = 222; };

      router = { hostname = "192.0.2.10"; user = "root"; };

      pve = { hostname = "192.0.2.10"; user = "root"; };
      deb-btc = { hostname = "192.0.2.10"; user = "root"; };
      deb-misc = { hostname = "192.0.2.10"; user = "root"; };
      deb-agent = { hostname = "192.0.2.10"; user = "root"; };
      deb-newt = { hostname = "192.0.2.10"; user = "root"; };
      deb-dokploy = { hostname = "192.0.2.10"; user = "root"; };
      deb-runner = { hostname = "192.0.2.10"; user = "root"; };

      vps-france = { hostname = "192.0.2.1"; user = "pycan"; };
      vps-germany = { hostname = "192.0.2.2"; user = "pycan"; };

      host-prod = { hostname = "192.0.2.3"; user = "user"; };
      host-dev = { hostname = "192.0.2.4"; user = "user"; };
      host-store = { hostname = "192.0.2.5"; user = "user"; };
    };
  };
}
