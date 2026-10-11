{ inputs }:
{ system, user, home ? "/home/${user}", isPro ? false, workspace }:

let
  pkgs = import ./mkPkgs.nix { inherit inputs; } system;
in inputs.homemanager.lib.homeManagerConfiguration {
  inherit pkgs;

  extraSpecialArgs = {
    inherit isPro workspace;
  };

  modules = [
    ../src/home.nix
    inputs.nix-index-database.homeModules.default
    inputs.catppuccin.homeModules.catppuccin
    {
      home = {
        username = user;
        homeDirectory = "${home}";
      };
    }
  ];
}