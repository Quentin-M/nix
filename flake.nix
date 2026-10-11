{
  inputs = {
      nixpkgs = {
      url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    };
    nixdarwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homemanager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Catppuccin Mocha across home-manager programs (src/home.nix `catppuccin`).
    catppuccin = {
      url = "github:catppuccin/nix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Upstream master for the Vision Pro (Multiplex) color-reply fix (herdrdev/herdr#5017),
    # unreleased after v0.9.3. Pin to the next release tag once it ships.
    herdr = {
      url = "github:herdrdev/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: let
    # Make functions
    mkHomeManager = import ./lib/mkHome.nix { inherit inputs; };
    mkDarwin = import ./lib/mkDarwin.nix { inherit inputs; };

    # Outputs
    in {
      darwinConfigurations = {
        # Home
        "Quentins-MacBook-Air" = mkDarwin { user = "mentalow"; system = "aarch64-darwin"; workspace = "/Users/mentalow/workspace"; };

        # BitMEX
        "Quentins-MacBook-Air-BitMEX" = mkDarwin { user = "quentin.machu-ext"; system = "aarch64-darwin"; isPro = true; workspace = "/Users/quentin.machu-ext/Workspace/q"; };
        "Quentins-Laptop" = mkDarwin { user = "qmachu"; system = "aarch64-darwin"; isPro = true; workspace = "/Users/qmachu/Workspace/q"; };
      };
      homeConfigurations = {
        "vagrant" = mkHomeManager { user = "vagrant"; system = "aarch64-linux"; home = "/home/vagrant"; workspace = "/home/vagrant/workspace"; };
        "mentalow" = mkHomeManager { user = "mentalow"; system = "x86_64-linux"; home = "/home/mentalow"; workspace = "/home/mentalow/workspace"; };
      };
    };
}
