{
  description = "Legacy Launcher Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    inherit (nixpkgs) lib;
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "legacy-launcher"
        ];
    };
  in rec {
    packages.${system}.default = pkgs.callPackage ./. {};

    overlays = {
      legacy-launcher = final: prev: {legacy-launcher = packages.${prev.system}.default;};
    };
  };
}
