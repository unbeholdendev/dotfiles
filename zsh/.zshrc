HISTFILE=${ZSH_HISTFILE:-~/.zsh_history}
HISTSIZE=50000
SAVEHIST=50000
setopt extended_history share_history hist_ignore_all_dups hist_verify hist_ignore_space interactive_comments 

autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

bindkey '^[[A' history-beginning-search-backward    # ↑
bindkey '^[[B' history-beginning-search-forward     # ↓
bindkey '^[OA' history-beginning-search-backward
bindkey '^[OB' history-beginning-search-forward

source <(fzf --zsh)
eval "$(zoxide init zsh)"

eval "$(dircolors -b)"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} 
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ll='ls -lah'
alias ..='cd ..'
alias ...='cd ../..'

dots() { "${DOTFILES:-$HOME/dotfiles}/dots.sh" }

autoload -Uz vcs_info add-zsh-hook
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' stagedstr '+'
zstyle ':vcs_info:git:*' formats ' (%b%u%c)'
zstyle ':vcs_info:git:*' actionformats ' (%b|%a%u%c)'
add-zsh-hook precmd vcs_info
setopt prompt_subst
PROMPT='%F{180}%~%f%F{244}${vcs_info_msg_0_}%f %(?.%F{71}.%F{167})❯%f '

source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
