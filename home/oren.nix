{ config, dotfiles, hermes, lib, pkgs, ... }:
let
  t3Dir = "${config.home.homeDirectory}/.t3";
  t3Port = "3773";
  forgejo = "https://git.home.unbeholden.dev";
  githubIdentity = "${config.xdg.configHome}/git/github-identity";

  agentSetup = pkgs.writeShellApplication {
    name = "agent-setup";
    runtimeInputs = with pkgs; [ codex coreutils git gnused jq ];
    text = builtins.readFile ../agents/setup.sh;
  };

  forgeLogin = pkgs.writeShellApplication {
    name = "forge-login";
    runtimeInputs = with pkgs; [ gh git tea ];
    text = ''
      if [[ -f ~/.forgejo-token ]] && ! tea logins list -o simple | grep -q '^forgejo '; then
        GITEA_SERVER_TOKEN=$(<~/.forgejo-token) tea login add --name forgejo --url ${forgejo} >/dev/null
      fi
      if [[ -f ~/.github-token ]]; then
        [[ -f ${config.xdg.configHome}/gh/hosts.yml ]] || gh auth login --with-token < ~/.github-token
        if ! git config --file ${githubIdentity} user.email >/dev/null; then
          read -r id login < <(gh api user --jq '[.id, .login] | @tsv')
          git config --file ${githubIdentity} user.name "$login"
          git config --file ${githubIdentity} user.email "$id+$login@users.noreply.github.com"
        fi
      fi
    '';
  };
in
{
  imports = [
    ./agents.nix
    ./common.nix
    ./nvim.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; [
    hermes.packages.${stdenv.hostPlatform.system}.minimal
    bun
    cargo
    go
    nodejs
    python3
    rustc
    (writeShellApplication {
      name = "t3pair";
      runtimeInputs = [ hostname-debian jq qrencode t3code ];
      text = ''
        url=$(t3 auth pairing create --base-dir ${t3Dir} --json \
          --base-url "http://$(hostname -I | cut -d' ' -f1):${t3Port}" | jq -r .pairUrl)
        printf %s "$url" | qrencode -t ansiutf8
        echo "$url"
      '';
    })
  ];

  home.activation = {
    agentSetup = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${lib.getExe agentSetup} ${dotfiles} || warnEcho "agent setup failed: rerun the switch"
    '';
    forgeLogin = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${lib.getExe forgeLogin} || warnEcho "forge login failed: T3 Code cannot read PRs"
    '';
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "agent";
      user.email = "335420059+unbeholdendev@users.noreply.github.com";
      credential.${forgejo}.helper =
        ''!f() { echo username=agent; echo "password=$(cat "$HOME/.forgejo-token")"; }; f'';
      credential."https://github.com".helper =
        ''!f() { echo username=x-access-token; echo "password=$(cat "$HOME/.github-token")"; }; f'';
    };
    includes = [{
      condition = "hasconfig:remote.*.url:https://github.com/**";
      path = githubIdentity;
    }];
  };

  # Neovim rewrites its lock, and agent cannot write root's clone.
  xdg.configFile."nvim/nvim-pack-lock.json".enable = false;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.whitelist.prefix = [ "${t3Dir}/worktrees/" ];
  };

  systemd.user.services.t3 = {
    Unit.Description = "T3 Code";
    Service = {
      Environment = [
        "PATH=${config.home.profileDirectory}/bin:/run/wrappers/bin:/run/current-system/sw/bin"
        "T3CODE_TELEMETRY_ENABLED=false"
        "DOCKER_HOST=unix://%t/docker.sock"
      ];
      WorkingDirectory = "%h";
      # A reboot can reuse the recorded PID, and t3 start then refuses to run.
      ExecStartPre = "${pkgs.coreutils}/bin/rm -f ${t3Dir}/userdata/server-runtime.json";
      ExecStart = "${lib.getExe' pkgs.t3code "t3"} start --no-browser --host 0.0.0.0 --port ${t3Port} --base-dir ${t3Dir}";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
