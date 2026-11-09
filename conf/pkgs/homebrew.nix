{ isPro ? false }:

let
  taps =
    let
      common = [
        "multiplex-term/tap"
        "typewhisper/tap"
        "fif7y/tap"
        { name = "involvex/youtube-music-cli"; clone_target = "https://github.com/involvex/youtube-music-cli.git"; }
      ];
      home = [
        "hashicorp/tap"
      ];
      pro = [
        "didhd/tap" # amazon-bedrock-client
      ];
    in common ++ (if isPro then pro else home);

  brews =
    let
      common = [
        "mas"          # let nix install mac app store apps
        "ykman"
        "gh"
        "uv"
        "xcodegen" # generates Multiplex.xcodeproj
        "swiftlint" # Multiplex build/lint dependency
        "multiplex-term/tap/mpx" # binds this machine to the Multiplex app
        "gnupg"
        "actionlint"
        "mpv" # playback for the YouTube Music TUIs (ytm-player loads libmpv)
        "yt-dlp"
        "involvex/youtube-music-cli/youtube-music-cli" # ymc, YouTube Music TUI
        # tools/harness: proof capture and terminal recordings
        "ffmpeg"
        "vhs"
        "d2"
        "graphviz"
        "tmux"
      ];
      home = [
        "wireguard-tools"
        "ansible"
      ];
      pro = [
        # (api build deps)
        "pkg-config"
        "cairo"
        "pango"
        "libpng"
        "jpeg"
        "giflib"
        "librsvg"
        "pixman"
        # work tooling
        "libpq"
        "logcli"
        "moon"
        "proto"
        "node"
        "redis"
        "jdtls"
        "openjdk@17"
      ];
    in common ++ (if isPro then pro else home);

  casks =
    let
      common = [
        "brave-browser"
        "iterm2"
        "herdr-app"
        "bettershot"
        "claude"
        "orbstack"
        "zed"
        "postico"
        "1password"
        "1password-cli"
        "tinycast" # launcher on Cmd+Space (home.nix)
        "fif7y/tap/dimble" # menu bar manager
        "dockdoor-pro" # Dock replacement
        "stats"
        "keka"
        "bloom" # Finder replacement
        "iina"
        "opendisk" # disk space analyser
        "codex"
        "claude-code@latest"
        "elgato-wave-link"
        "hammerspoon" # volume keys -> Wave Link mix (conf/hammerspoon)
        "focusrite-control" # Scarlett 6i6 2nd gen; focusrite-control-2 only drives 4th gen+
        "obsidian"
        "typewhisper/tap/typewhisper"
      ];
      home = [
        "lulu" # outbound firewall; the work MDM blocks its network extension
        "discord"
        "whatsapp"
        "eddie"
        "hashicorp/tap/hashicorp-vagrant"
        "virtualbox"
      ];
      pro = [
        "slack"
        "drawio"
        "datagrip"
        "temurin@21"
      ];
    in common ++ (if isPro then pro else home);

  # Login Items, applied by home.nix: exactly this list, anything else is removed.
  loginItems =
    let
      common = [
        "/Applications/Tinycast.app"
        "/Applications/Dimble.app"
        "/Applications/DockDoor Pro.app"
        "/Applications/Hammerspoon.app"
        "/Applications/BetterShot.app"
        "/Applications/Stats.app"
      ];
      home = [
        "/Applications/LuLu.app"
      ];
    in common ++ (if isPro then [] else home);

in { inherit taps brews casks loginItems; }
