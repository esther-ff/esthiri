{
  description = "Esthiri";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    crane.url = "github:ipetkov/crane";
    stable-niri.url = "github:YaLTeR/niri/v25.05.1";
    unstable-niri.url = "github:YaLTeR/niri";
  };

  outputs = inputs@{ self, nixpkgs, stable-niri, crane, ... }:
    let
      inherit (nixpkgs.lib) genAttrs;

      genPackage = pkgs:
        let
          buildNiri = import ./package.nix crane pkgs;
          package =
            pkgs.callPackage (buildNiri inputs.stable-niri "25.05.1") { };
        in {
          default = package;
          niri = package;
        };

    in let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = genAttrs systems;
    in {
      packages = forAllSystems
        (system: genPackage inputs.nixpkgs.legacyPackages.${system});
    };
}
