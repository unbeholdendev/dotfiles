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

  # `dcup` and the `dots` function found the clone by resolving `~/.zshrc`,
  # which is a store path now. This names it instead. It sits beside the
  # program that holds the same path, so a container, where install.sh writes
  # the file itself, is not given a second answer.
  home.file.".dots-path".text = "${dotfiles}\n";
}
