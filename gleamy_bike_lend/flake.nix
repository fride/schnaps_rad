{
  description = "My gleam monorepo";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nix-gleam.url = "github:arnarg/nix-gleam";

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      nix-gleam,
    }:
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            nix-gleam.overlays.default
          ];
        };
        lib = pkgs.lib;
        stdenv = pkgs.stdenv;
      in
      {
        devShells.default = pkgs.mkShell rec {
          packages =
            [
              pkgs.gleam
              pkgs.rebar3
              pkgs.nodejs_22
              pkgs.erlang_27
              pkgs.xcbuild
            ]
            ++ lib.optionals stdenv.isDarwin (
              with pkgs.darwin.apple_sdk.frameworks;
              [
                Cocoa
                CoreServices
              ]
            );
        };      
      }
    ));
}
