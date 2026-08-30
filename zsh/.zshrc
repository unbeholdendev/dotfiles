[[ -z ${ZSH_HISTFILE:-} && -d /history ]] && ZSH_HISTFILE=/history/zsh_history
HISTFILE=${ZSH_HISTFILE:-~/.zsh_history}
HISTSIZE=50000
SAVEHIST=50000
setopt extended_history share_history hist_ignore_all_dups hist_verify hist_ignore_space interactive_comments

autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

for d in ~/.nix-profile/share /usr/share; do
  if [[ -r $d/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source $d/zsh-autosuggestions/zsh-autosuggestions.zsh
    break
  fi
done

bindkey '^[[A' history-beginning-search-backward    # ↑
bindkey '^[[B' history-beginning-search-forward     # ↓
bindkey '^[OA' history-beginning-search-backward
bindkey '^[OB' history-beginning-search-forward

source <(fzf --zsh)
eval "$(zoxide init zsh)"

export EDITOR=nvim
export VISUAL=nvim

# dircolors has no TERM entry for foot, and an unknown TERM gives an empty
# LS_COLORS, which turns off colour for ls and for the completion menu.
eval "$(TERM=xterm-256color dircolors -b)"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ll='ls -lah'
alias ..='cd ..'
alias ...='cd ../..'

# On a host home-manager installs `dots`, with the clone and the flake output
# written into it. A container cannot have that: the clone is at a path the
# image and the mount decide, so install.sh works it out at run time.
if ! command -v dots >/dev/null; then
  dots() {
    if [[ -z ${DOTFILES:-} ]]; then
      echo "no DOTFILES: run the clone's install.sh once to write ~/.dots-path" >&2
      return 1
    fi
    "$DOTFILES/install.sh" "$@"
  }
fi

autoload -Uz vcs_info add-zsh-hook
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' stagedstr '+'
zstyle ':vcs_info:git:*' formats ' (%b%u%c)'
zstyle ':vcs_info:git:*' actionformats ' (%b|%a%u%c)'
add-zsh-hook precmd vcs_info
setopt prompt_subst
PROMPT=''
[[ -n ${SSH_CONNECTION:-} ]] && PROMPT='%F{109}%m%f '
PROMPT+='%F{180}%~%f%F{244}${vcs_info_msg_0_}%f %(?.%F{71}.%F{167})❯%f '

for d in ~/.nix-profile/share /usr/share; do
  if [[ -r $d/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source $d/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    break
  fi
done
