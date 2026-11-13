typeset -U path PATH

path=(~/.local/bin $path)

# A niri session reads none of the installer's own files.
if [[ -d ~/.nix-profile/bin ]]; then
  path=(~/.nix-profile/bin $path)
  export XDG_DATA_DIRS=~/.nix-profile/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
  [[ -r ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]] &&
    source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
fi
