{
  isPro ? false,
  isDarwin,
  workspace,
}:
let
  common = {
    claude = "${workspace}/tools/harness/go/cmd/claude/main.sh"; # --omp | --codex | --rig pick another harness
    rig = "${workspace}/tools/harness/go/cmd/claude/main.sh --rig"; # OpenRig CLI with the harness wiring
    ls = "eza";
    cd = "z";
    lg = "lazygit";
    rgb = "batgrep";
    man = "batman";
    find = "fd";
    dig = "doggo";
    cat = "bat";
    du = "dust";

    python = "python3";
    d = if isDarwin then "docker" else "sudo docker"; # OrbStack needs no sudo
  };

  darwin = {
    intel = "env /usr/bin/arch -x86_64 /bin/zsh";
    arm = "env /usr/bin/arch -arm64 /bin/zsh";
  };

  linux = {
    sr = "systemctl daemon-reload";
    j = "journalctl";
  };

  proSudo = {
    s = "/Applications/Privileges.app/Contents/MacOS/PrivilegesCLI --status 2>&1 | grep administrator || /Applications/Privileges.app/Contents/MacOS/PrivilegesCLI --add --reason \"To run sudo commands for a while\" && sudo";
  };

  homeSudo = {
    s = "sudo";
  };
in
  common // (if isDarwin then darwin else linux) // (if isPro then proSudo else homeSudo)
