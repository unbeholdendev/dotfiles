FROM fedora:44

RUN dnf install -y --setopt=install_weak_deps=False \
      zsh stow git niri ripgrep \
      zsh-autosuggestions zsh-syntax-highlighting \
    && dnf clean all

ARG FJMCP_VERSION=2.30.2
RUN set -o pipefail && curl -sSfL "https://codeberg.org/goern/forgejo-mcp/releases/download/v${FJMCP_VERSION}/forgejo-mcp_${FJMCP_VERSION}_linux_amd64.tar.gz" \
    | tar -xz -C /usr/local/bin --strip-components=1 "forgejo-mcp_${FJMCP_VERSION}_linux_amd64/forgejo-mcp"

 RUN git config --system user.name "agent" \
  && git config --system user.email "335420059+unbeholdendev@users.noreply.github.com" \
  && git config --system credential.helper \
     '!f() { echo username=agent; echo "password=$(cat "$HOME/.forgejo-token")"; }; f'

WORKDIR /root

RUN curl -fsSL https://claude.ai/install.sh | bash
RUN curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh
ENV PATH="/root/.local/share/mise/shims:/root/.local/bin:${PATH}"

# The pinned tools are baked into the image so a rebuild does not fetch them
# again. post-create stows the same file over this path, and stow refuses to
# overwrite a regular file, so the copy must not stay.
COPY mise/.config/mise/config.toml /root/.config/mise/config.toml
RUN mise install && rm /root/.config/mise/config.toml
