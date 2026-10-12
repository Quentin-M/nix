#
# All nix-darwin options: https://mynixos.com/nix-darwin/options/system.defaults
#
{
  pkgs,
  user,
  isPro,
  ...
}: let
  hb = import ../conf/pkgs/homebrew.nix { inherit isPro; };
in {
  # Nix Daemon & Nix auto-update.
  # We use Determinate Nix installer instead of nix-darwin's management.
  # Custom nix settings live in /etc/nix/nix.custom.conf, managed below.
  nix.enable = false;
  environment.etc."nix/nix.custom.conf" = {
    # Hash of the stock file written by the Determinate installer, so nix-darwin may replace it.
    knownSha256Hashes = ["3bd68ef979a42070a44f8d82c205cfd8e8cca425d91253ec2c10a88179bb34aa"];
    text = ''
      # quentin-m: our herdr builds, pushed by `make nix-push`
      extra-substituters = https://nix-community.cachix.org https://quentin-m.cachix.org
      extra-trusted-public-keys = nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWHvwqA7tdQ= quentin-m.cachix.org-1:BksQHQGmN1V3s3OJ7s2Sj6NanWwxeVkiaxZKKtbBpUw=
    '';
  };

  system = {
    stateVersion = 4;
    primaryUser = user;
  };

  # Fonts
  fonts.packages = with pkgs; [meslo-lgs-nf];

  # BitMEX internal PKI root CA for Node (IT appends this to /etc/zshrc, which nix-darwin owns).
  environment.variables = if isPro then {NODE_EXTRA_CA_CERTS = "/etc/bitmex-ca-bundle-2026.pem";} else {};
  # Move an externally edited /etc/zshrc aside so activation never aborts on it.
  system.activationScripts.preActivation.text = ''
    if [[ -e /etc/zshrc && $(readlink /etc/zshrc) != /etc/static/zshrc ]]; then
      mv /etc/zshrc "/etc/zshrc.before-nix-darwin.$(date +%s)"
    fi
  '';

  # System packages.
  environment.systemPackages = with pkgs; [
    pinentry_mac # yubikey PIN UI
    yubikey-personalization # yubikey tool
  ];

  # Homebrew
  homebrew = {
    enable = true;
    inherit (hb) taps brews casks;
    masApps = {};
    prefix = "/opt/homebrew";

    # Brew holds only what conf/pkgs/homebrew.nix lists; anything else is zapped.
    onActivation.cleanup = "zap";
    global.autoUpdate = false;
  };

  # Darwin fun
  system.defaults = {
    # Dock
    dock = {
      autohide = true;
      mru-spaces = false;
      orientation = "bottom";
      showhidden = false;
      show-recents = true;
      persistent-apps = hb.dock;
      # fan display / sorting: https://github.com/nix-darwin/nix-darwin/issues/982
      persistent-others = [
        "/Users/${user}/Downloads/"
      ];
    };

    # Finder
    finder = {
      AppleShowAllFiles = true;
      AppleShowAllExtensions = true;
      QuitMenuItem = true;
      CreateDesktop = false;
      ShowPathbar = true;
      ShowStatusBar = true;
      FXPreferredViewStyle = "Nlsv";
      FXEnableExtensionChangeWarning = false;
    };

    # Trackpad
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
    };
    NSGlobalDomain = {
      "com.apple.swipescrolldirection" = false;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      ApplePressAndHoldEnabled = false; # held keys repeat (nvim hjkl)
    };
    screencapture.location = "~/Downloads";

    # Hide date/time - we use Stats' date/time instead
    menuExtraClock = {
      IsAnalog = true;
      ShowDate = 2;
    };
  };

  # TouchID for sudo, including inside herdr (reattach)
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # Also set in home.nix; here it makes nix-darwin write /etc/zshenv to load the environment.
  # Zim's completion module owns compinit; the global one in /etc/zshrc makes it warn.
  # Starship owns the prompt; the default `promptinit; prompt suse` only costs startup time.
  programs.zsh = {
    enable = true;
    enableCompletion = false;
    enableBashCompletion = false;
    promptInit = "";
  };
}
