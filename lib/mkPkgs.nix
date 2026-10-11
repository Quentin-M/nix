# Nixpkgs with our overlays, shared by mkDarwin and mkHome.
{inputs}: system:
import inputs.nixpkgs {
  inherit system;
  overlays = [inputs.herdr.overlays.default];
  config.allowUnfree = true;
}
