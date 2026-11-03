let
  inherit (builtins) attrNames attrValues concatLists concatStringsSep filter getEnv getFlake listToAttrs map parseDrvName;

  packages = dir:
    let
      flake = getFlake "path:${dir}";
      home = c: c.home.packages;
      nixos = c: c.config.environment.systemPackages
        ++ concatLists (map home (attrValues c.config.home-manager.users));
      entry = p:
        let d = parseDrvName p.name;
        in { name = p.pname or d.name; value = p.version or d.version; };
    in
    listToAttrs (map entry (
      concatLists (map nixos (attrValues flake.nixosConfigurations))
      ++ concatLists (map (c: home c.config) (attrValues flake.homeConfigurations))
    ));

  old = packages (getEnv "BASE");
  new = packages (getEnv "HEAD");
  changed = filter (n: old.${n} or null != new.${n} or null) (attrNames (old // new));
  cell = v: if v == null then "—" else if v == "" then "(none)" else "`${v}`";
  row = n: "| ${n} | ${cell (old.${n} or null)} | ${cell (new.${n} or null)} |";
in
{
  body =
    if changed == [ ] then "No installed package changes version."
    else concatStringsSep "\n" ([
      "Installed packages that change version:"
      ""
      "| Package | Old | New |"
      "| --- | --- | --- |"
    ] ++ map row changed);
}
