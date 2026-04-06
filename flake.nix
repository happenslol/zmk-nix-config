{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    zmk-nix,
  }: let
    forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
  in {
    packages = forAllSystems (system: let
      mkSplitKeyboard = {
        name,
        shield,
        board,
      }:
        zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
          inherit name shield board;
          src = nixpkgs.lib.sourceFilesBySuffices self [".conf" ".keymap" ".yml"];
          zephyrDepsHash = "sha256-mUJpGWlU+rGbcWtKs/SuombCJ3RcIDMTiuMicwLX1D4=";
        };
    in {
      sofle = mkSplitKeyboard {
        name = "sofle";
        shield = "sofle_%PART%";
        board = "nice_nano@2.0.0";
      };
      corne = mkSplitKeyboard {
        name = "corne";
        shield = "corne_%PART%";
        board = "nice_nano@2.0.0";
      };

      update = zmk-nix.packages.${system}.update;
    });

    devShells = forAllSystems (system: {
      default = zmk-nix.devShells.${system}.default;
    });
  };
}
