{ pkgs ? import <nixpkgs> {} }:

pkgs.callPackage ./legacy-launcher.nix {}

