FROM fedora:44

RUN dnf install -y --setopt=install_weak_deps=False \
      zsh stow git niri fzf zoxide ripgrep \
      zsh-autosuggestions zsh-syntax-highlighting \
    && dnf clean all

ARG FJMCP_VERSION=2.30.2
RUN set -o pipefail && curl -sSfL "https://codeberg.org/goern/forgejo-mcp/releases/download/v${FJMCP_VERSION}/forgejo-mcp_${FJMCP_VERSION}_linux_amd64.tar.gz" \
    | tar -xz -C /usr/local/bin --strip-components=1 "forgejo-mcp_${FJMCP_VERSION}_linux_amd64/forgejo-mcp"

 RUN git config --system user.name "agent" \
  && git config --system user.email "335420059+unbeholdendev@users.noreply.github.com" \
  && git config --system credential.helper \
     '!f() { echo username=agent; echo "password=$(cat /home/dev/.forgejo-token)"; }; f'

RUN useradd -m -s /usr/bin/zsh dev
USER dev
WORKDIR /home/dev

RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/dev/.local/bin:${PATH}"
