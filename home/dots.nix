{ dotfiles, nixos, pkgs, target, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "dots";
      text = ''
        git -C ${dotfiles} switch main
        git -C ${dotfiles} pull --rebase
        ${if nixos then "sudo nixos-rebuild" else "home-manager"} \
          switch --flake ${dotfiles}#${target}
      '';
    })
  ];

  home.file.".dots-path".text = "${dotfiles}\n";
}
