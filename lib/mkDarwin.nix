{inputs}: {
  system,
  user,
  home ? "/Users/${user}",
  isPro ? false,
  workspace,
}: let
  pkgs = import ./mkPkgs.nix {inherit inputs;} system;
in
  inputs.nixdarwin.lib.darwinSystem {
    inherit system;
    specialArgs = {inherit pkgs inputs user isPro;};

    modules = [
      # Nix-darwin configuration
      ../src/darwin.nix

      # Home-manager configuration
      inputs.homemanager.darwinModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          sharedModules = [inputs.nix-index-database.homeModules.default inputs.catppuccin.homeModules.catppuccin];
          backupFileExtension = "backup";
          extraSpecialArgs = {inherit isPro workspace;};
          users.${user} = import ../src/home.nix;
        };
        users.users."${user}".home = home; # https://github.com/nix-community/home-manager/issues/4026
      }
    ];
  }
