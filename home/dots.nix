{ dotfiles, pkgs, target, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "dots";
      text = ''
        git -C ${dotfiles} switch main
        git -C ${dotfiles} pull --rebase --autostash
        home-manager switch --flake ${dotfiles}#${target}
      '';
    })
  ];

  home.file.".dots-path".text = "${dotfiles}\n";
}
