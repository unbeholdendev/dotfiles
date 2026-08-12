FROM fedora:44

RUN dnf install -y --setopt=install_weak_deps=False \
      zsh stow git niri fzf zoxide ripgrep \
      zsh-autosuggestions zsh-syntax-highlighting \
    && dnf clean all

RUN useradd -m -s /usr/bin/zsh dev
USER dev
WORKDIR /home/dev
