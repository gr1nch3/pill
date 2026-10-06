{
  description = "Pill - Dynamic Island shell (Wayland/Quickshell)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    forAllSystems = fn:
      nixpkgs.lib.genAttrs nixpkgs.lib.platforms.linux (
        system: fn nixpkgs.legacyPackages.${system}
      );
  in {
    packages = forAllSystems (pkgs: rec {
      pill = pkgs.callPackage ./nix {
        quickshell = inputs.quickshell.packages.${pkgs.system}.default;
      };
      default = pill;
    });

    homeManagerModules.default = import ./nix/hm-module.nix self;
  };
}
