{ pkgs, ... }:
let
  # A container's hostname is a random id, so it cannot name a flake output.
  # The name is fixed, and the two facts that vary are read from the
  # environment: the image chooses the user, and install.sh runs the build with
  # `--impure` for these alone.
  fromEnv = name:
    let v = builtins.getEnv name;
    in if v != "" then v else throw "${name} is empty: run install.sh, not nix build";
in
{
  imports = [
    ./nvim.nix
    ./zsh.nix
  ];

  # What `mise/` pinned. nix is here because install.sh points ~/.nix-profile
  # away from the one the installer made, so an interactive shell would
  # otherwise have no nix at all.
  home.packages = with pkgs; [
    claude-code
    forgejo-mcp
    fzf
    neovim
    nix
    zoxide
  ];

  home.username = fromEnv "HOME_USER";
  home.homeDirectory = fromEnv "HOME";
  home.stateVersion = "26.05";

  # No programs.home-manager: install.sh builds the activation package itself,
  # so the CLI is 57M of store paths nothing in a container calls.
}
