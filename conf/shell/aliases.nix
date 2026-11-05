{
  isDarwin,
  workspace,
}:
let
  common = {
    claude = "${workspace}/tools/harness/go/cmd/claude/main.sh"; # --omp | --codex | --oc pick another harness
    omp = "${workspace}/tools/harness/go/cmd/claude/main.sh --omp"; # omp with the harness config (one config dir)
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
    s = "sudo";
  };

  darwin = {
    intel = "env /usr/bin/arch -x86_64 /bin/zsh";
    arm = "env /usr/bin/arch -arm64 /bin/zsh";
  };

  linux = {
    sr = "systemctl daemon-reload";
    j = "journalctl";
  };

in
  common // (if isDarwin then darwin else linux)
