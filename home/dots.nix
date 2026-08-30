{ dotfiles, pkgs, target, ... }:
{
  # A host never runs install.sh: the clone and the output are written in here
  # rather than worked out at run time from a file stow happens to have placed.
  home.packages = [
    (pkgs.writeShellApplication {
      name = "dots";
      text = ''
        git -C ${dotfiles} pull --rebase --autostash
        home-manager switch --flake ${dotfiles}#${target}
      '';
    })
  ];
}
