{ isPro ? false }:

let
  taps =
    let
      common = [
        "multiplex-term/tap"
        "typewhisper/tap"
        { name = "involvex/youtube-music-cli"; clone_target = "https://github.com/involvex/youtube-music-cli.git"; }
        { name = "abue-ammar/tinycast"; trusted = true; }
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
        "abue-ammar/tinycast/tinycast" # launcher on Cmd+Space (home.nix)
        "thaw" # menu bar manager
        "loop" # window manager
        "stats"
        "keka"
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

  dock =
    let
      home = [
        "/Applications/Brave Browser.app"
        "/System/Applications/Mail.app"
        "/System/Applications/Calendar.app"
        "/Applications/Claude.app"
        "/Applications/Zed.app"
        "/Applications/iTerm.app"
        "/Applications/Herdr.app"
      ];
      pro = [
        "/Applications/Brave Browser.app"
        "/Applications/Google Chrome.app"
        "/System/Applications/Calendar.app"
        "/System/Applications/Mail.app"
        "/Applications/Slack.app"
        "/Applications/Zed.app"
        "/Applications/iTerm.app"
        "/Applications/Herdr.app"
      ];
    in if isPro then pro else home;

in { inherit taps brews casks dock; }
