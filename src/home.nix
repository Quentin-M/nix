#
# configuration options: https://mynixos.com/home-manager/options
#
{
  pkgs,
  config,
  isPro ? false,
  workspace,
  ...
}: let
  # Repo checkout, for out-of-store symlinks that apps write back to.
  repo = "${workspace}/infra/nix";

  shellAliases = import ../conf/shell/aliases.nix {
    inherit isPro workspace;
    inherit (pkgs.stdenv) isDarwin;
  };

  packages = with pkgs; [
    # zsh/starship/zim requirements
    starship
    pandoc
    mdcat
    bat-extras.batman
    bat-extras.batgrep
    bat-extras.batdiff
    bat-extras.batwatch
    bat-extras.prettybat
    choose
    tree-sitter
    zoxide
    doggo  # Replaces unmaintained dogdns
    dust
    hyperfine

    # we like gnu tools
    coreutils # sha256sum, base64, etc
    moreutils # sponge, parallel
    gawk
    gnugrep
    gnumake
    gnused
    gnutar
    curl
    openssl
    unixtools.watch

    # build tools
    gcc
    stdenv.cc.cc.lib # gcc runtime libraries including libatomic.so.1
    ncurses.dev # ncurses headers for building
    autoconf
    automake
    cmake
    wget

    # shell utilities
    tldr
    fd
    ripgrep
    git
    awscli2
    kubectl
    kubectx
    devcontainer

    # nvim nix tooling (neovim itself installed via programs.neovim below)
    nixd
    cachix
    alejandra
    deadnix
    statix

    # k8s / deploy
    kubelogin-oidc # kubectl oidc-login
    kubernetes-helm
    argocd
    skaffold

    # Runtimes / managers
    mise # also provides bun, node, go, terraform (~/.config/mise/config.toml)
    pnpm

    # AI coding agents
    herdr # agent multiplexer, used with Multiplex on Vision Pro (upstream master, see flake.nix)

    # apps
    mtr
    ipcalc
    ipmitool
    htop
    jq
    pgcli
    weechat
    websocat # Wave Link JSON-RPC from Hammerspoon
  ];
in
  with pkgs; {
    # Home-manager
    programs.home-manager.enable = true;
    home = {
      stateVersion = "25.11";
      inherit packages;
      sessionPath = ["$HOME/.local/bin" "${workspace}/tmp/go/bin"] ++ lib.optional stdenv.isDarwin "/opt/homebrew/bin";
      sessionVariables = {
        GOPATH = "${workspace}/tmp/go/";
        KUBE_EDITOR = "nvim";
        WEECHAT_HOME = "$HOME/.config/weechat";
        EZA_CONFIG_DIR = "${config.xdg.configHome}/eza"; # macOS default is ~/Library/Application Support
      };

      # Git signing key: first available wins; sk keys last since they need a physical touch.
      activation.setupGitSigning = config.lib.dag.entryAfter ["writeBoundary"] ''
        for key in "$HOME"/.ssh/id_ed25519 "$HOME"/.ssh/id_rsa "$HOME"/.ssh/id_ed25519_sk*; do
          [[ -f $key && $key != *.pub ]] && break
          key=
        done
        if [[ -n $key ]]; then
          $DRY_RUN_CMD ln -sf "$key" "$HOME/.ssh/git_signing_key"
          for pub in "$HOME"/.ssh/id_*.pub; do
            [[ -f $pub ]] && printf 'quentin@machu.dev %s\nquentin@bitmex.com %s\n' "$(<"$pub")" "$(<"$pub")"
          done > "$HOME/.ssh/allowed_signers"
        else
          echo "WARNING: No SSH key found for git signing (looked for id_ed25519, id_rsa, id_ed25519_sk*)"
        fi
      '';

      activation.sshControlDir = config.lib.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p -m 700 "$HOME/.ssh/cm"
      '';

      # Herdr agent-state integrations for claude, omp and codex. Idempotent.
      activation.setupHerdrIntegrations = config.lib.dag.entryAfter ["writeBoundary" "installPackages"] ''
        PATH="${config.home.path}/bin:/opt/homebrew/bin:$PATH"
        if command -v herdr &>/dev/null; then
          for agent in claude omp codex; do
            herdr integration status 2>/dev/null | grep -q "^$agent: current" \
              || $DRY_RUN_CMD herdr integration install "$agent"
          done
        fi
      '';

      # Wave Link: seed the repo config on a fresh Mac (it rewrites the file, so no symlink;
      # `wavelink backup|restore` syncs after that) and list Marketplace plugins to install.
      activation.setupWaveLink = config.lib.dag.entryAfter ["writeBoundary"] ''
        if [[ "$(uname)" == "Darwin" ]]; then
          wl="$HOME/Library/Application Support/com.elgato.WaveLink3"
          if [[ ! -f $wl/config.json ]]; then
            $DRY_RUN_CMD mkdir -p "$wl"
            $DRY_RUN_CMD cp "${repo}/conf/wavelink/config.json" "$wl/config.json"
            $DRY_RUN_CMD chmod 644 "$wl/config.json"
          fi
          for c in MONOCORE ElgatoNoiseRemoval ElgatoCompressor ElgatoEq ElgatoDeEsser; do
            ls -d "$HOME/Library/Audio/Plug-Ins/Components/$c"*.component &>/dev/null \
              || echo "Wave Link: install the $c plugin from Marketplace"
          done
        fi
      '';

      # Free Cmd+Space for Tinycast: disable Spotlight's "Show Spotlight search" (id 64).
      # -dict-add edits one entry; a plain write would replace every symbolic hotkey.
      activation.disableSpotlightHotkey = config.lib.dag.entryAfter ["writeBoundary"] ''
        if [[ "$(uname)" == "Darwin" ]]; then
          $DRY_RUN_CMD /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
            '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'
          $DRY_RUN_CMD /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
        fi
      '';

      # uv tools (requires uv from brews, macOS only): it2 for Claude Code team mode,
      # ytm-player for the `ytm` YouTube Music TUI.
      activation.installUvTools = config.lib.dag.entryAfter ["writeBoundary" "installPackages"] ''
        if [[ "$(uname)" == "Darwin" ]]; then
          PATH="${config.home.path}/bin:/opt/homebrew/bin:$PATH"
          if command -v uv &>/dev/null; then
            for tool in it2 ytm-player; do
              if ! uv tool list 2>/dev/null | grep -q "^$tool "; then
                $DRY_RUN_CMD uv tool install --force "$tool"
              fi
            done
          fi
        fi
      '';
    };

    # Nix-index with the weekly prebuilt database; `, cmd` runs any nixpkgs binary.
    programs.nix-index.enable = true;
    programs.nix-index-database.comma.enable = true;

    # Catppuccin Mocha for every enabled program it has a port for (bat, delta, zed, btop,
    # k9s, fzf, eza, atuin, lazygit). nvim (AstroNvim), starship, herdr and iTerm2 set it
    # in their own config; zsh highlighting is fast-syntax-highlighting (zshrc).
    catppuccin = {
      enable = true;
      flavor = "mocha";
      nvim.enable = false;
      zsh-syntax-highlighting.enable = false;
    };
    xdg.configFile."fsh/catppuccin-mocha.ini".source = "${fetchFromGitHub {
      owner = "catppuccin";
      repo = "zsh-fsh";
      rev = "a9bdf479f8982c4b83b5c5005c8231c6b3352e2a";
      hash = "sha256-WeqvsKXTO3Iham+2dI1QsNZWA8Yv9BHn1BgdlvR8zaw=";
    }}/themes/catppuccin-mocha.ini";

    programs.bat = {
      enable = true;
      config.style = "-numbers";
    };
    # Zed: app + `zed` CLI come from the cask; settings merge into the mutable settings.json.
    programs.zed-editor = {
      enable = stdenv.isDarwin;
      package = null;
    };
    programs.btop.enable = true;
    programs.k9s.enable = true;
    programs.lazygit.enable = true;
    programs.fzf = {
      enable = true;
      enableZshIntegration = false; # Ctrl-R is atuin's; only FZF_DEFAULT_OPTS colors wanted
    };
    programs.eza = {
      enable = true;
      enableZshIntegration = false; # `ls` alias lives in conf/shell/aliases.nix
    };

    # Atuin: searchable shell history on Ctrl-R, local only (no sync server).
    programs.atuin = {
      enable = true;
      enableZshIntegration = false; # cached in conf/zsh/zshrc
      flags = ["--disable-up-arrow"];
      settings = {
        auto_sync = false;
        update_check = false;
        style = "compact";
        inline_height = 20;
        # Never record commands that carry credentials.
        history_filter = ["(?i)\\w*(key|secret|token)\\w*="];
      };
    };

    # Direnv: per-project env on cd, with cached `use flake`.
    programs.direnv = {
      enable = true;
      enableZshIntegration = false; # cached in conf/zsh/zshrc
      nix-direnv.enable = true;
      config.global.hide_env_diff = true;
    };

    # ZSH
    programs.zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      enableCompletion = false;
      history.ignoreAllDups = true;
      sessionVariables = {
        WORKSPACE = workspace;
        TZDIR = "/usr/share/zoneinfo";
      };
      envExtra = builtins.readFile ../conf/zsh/zshenv;
      initContent = builtins.readFile ../conf/zsh/zshrc;
      inherit shellAliases;
    };
    # home-manager's history block runs `mkdir -p "$(dirname "$HISTFILE")"`: two execs per
    # shell (~100ms each under EDR) for a dir that is ZDOTDIR itself.
    home.file."${lib.removePrefix "${config.home.homeDirectory}/" config.programs.zsh.dotDir}/.zshrc".text = lib.mkForce (
      builtins.replaceStrings [''mkdir -p "$(dirname "$HISTFILE")"''] [''[[ -d ''${HISTFILE:h} ]] || mkdir -p ''${HISTFILE:h}'']
      config.programs.zsh.initContent
    );
    xdg.configFile."zsh/.zimrc".source = ../conf/zsh/zimrc;
    xdg.configFile."zsh/.zim/zimfw.zsh".source = "${zimfw}/zimfw.zsh";
    xdg.configFile."starship.toml".source = ../conf/zsh/starship.toml;
    home.file.".hushlogin".text = "";

    # Herdr - out-of-store so its settings UI can write back.
    xdg.configFile."herdr/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${repo}/conf/herdr/config.toml";

    # iTerm2 - loads all settings from conf/iterm2/com.googlecode.iterm2.plist and writes
    # every change straight back to it (save mode 2 = automatically). Machine-local state
    # (NS*, SU*, NoSync* keys) stays in ~/Library/Preferences.
    # Option+Left/Right are deliberately unmapped: herdr's kitty keyboard protocol strips the
    # ESC from "send ESC b/f" remaps; the native ESC[1;3D/C is bound to word movement in zshrc.
    targets.darwin.defaults."com.googlecode.iterm2" = lib.mkIf stdenv.isDarwin {
      PrefsCustomFolder = "${repo}/conf/iterm2";
      LoadPrefsFromCustomFolder = true;
      NoSyncNeverRemindPrefsChangesLostForFile = true;
      NoSyncNeverRemindPrefsChangesLostForFile_selection = 2;
    };

    # Tinycast palette on Cmd+Space: its HotKeyBinding JSON, kVK_Space (49) + cmdKey (256).
    targets.darwin.defaults."com.tinycast.app" = lib.mkIf stdenv.isDarwin {
      "hotkey.togglePalette" = ''{"combo":{"_0":{"carbonKeyCode":49,"carbonModifiers":256}}}'';
    };

    # Git
    programs.git = {
      enable = true;
      settings =
        {
          merge = {conflictstyle = "diff3";};
          push = {default = "current";};
          fetch = {prune = true;};
          # No fsmonitor: its per-repo daemon never exits, and every agent worktree spawns one.
          core = {untrackedCache = true;};
          rerere = {enabled = true;};
          diff = {algorithm = "histogram";};
          init = {defaultBranch = "main";};
          branch = {sort = "-committerdate";};
          pull = {rebase = true;};
          rebase = {"autosquash" = true;};
          alias = {
            fix = "!git log -n 50 --pretty=format:'%h %s' --no-merges | fzf | choose 0 | xargs -o git commit --fixup";
          };
          "gpg \"ssh\"".allowedSignersFile = "~/.ssh/allowed_signers";
          user = {
            name = "Quentin Machu";
            email = if isPro then "quentin@bitmex.com" else "quentin@machu.dev";
          };
        };
      signing = {
        format = "ssh";
        key = "~/.ssh/git_signing_key";
        signByDefault = true;
      };
      # Hourly prefetch + daily gc/commit-graph for the main workspace repo.
      maintenance = {
        enable = true;
        repositories = [workspace];
      };
      ignores = [
        ".DS_Store"
        ".env"
        "**/.claude/settings.local.json"
      ];
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        side-by-side = true;
      };
    };

    # Linux only: macOS uses the 1Password agent (see zshrc).
    services.ssh-agent.enable = stdenv.isLinux;

    # SSH
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*" = {
          ControlMaster = "auto";
          # One socket per host hash; the master removes it after ControlPersist idle.
          ControlPath = "~/.ssh/cm/%C";
          ControlPersist = "600";
          AddKeysToAgent = "yes";
          ForwardAgent = true;
          Compression = true;
          ServerAliveInterval = 60;
          ServerAliveCountMax = 3;
          SetEnv = { TERM = "xterm-256color"; };
          LogLevel = "ERROR";
        } // lib.optionalAttrs pkgs.stdenv.isDarwin {
          IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
        } // lib.optionalAttrs isPro {
          ServerAliveInterval = 900;
          Ciphers = "aes128-ctr,aes192-ctr,aes256-ctr";
          MACs = "hmac-sha1,hmac-sha2-256,hmac-sha2-512";
        };
      };
    };
    home.file.".ssh/config".force = true;

    # AstroNvim: sideloadInitLua prevents home-manager from writing to nvim/init.lua,
    # which would conflict with our out-of-store symlink for the whole .config/nvim dir.
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      sideloadInitLua = true;
      withRuby = false;
      withPython3 = false;
      defaultEditor = true;
    };
    home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${repo}/conf/nvim";

    # Weechat
    home.file.".config/weechat".source = config.lib.file.mkOutOfStoreSymlink "${repo}/conf/weechat";

    # Hammerspoon (volume keys -> Wave Link) and the Wave Link config sync script
    home.file.".hammerspoon".source = config.lib.file.mkOutOfStoreSymlink "${repo}/conf/hammerspoon";
    home.file.".local/bin/wavelink".source = config.lib.file.mkOutOfStoreSymlink "${repo}/conf/wavelink/wavelink.sh";
  }
