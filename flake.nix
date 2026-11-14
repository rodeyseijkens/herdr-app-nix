{
  description = "Herdr - terminals and coding agents that keep running";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {self, nixpkgs}: let
    systems = ["x86_64-linux" "aarch64-linux"];
    versions = builtins.fromJSON (builtins.readFile ./versions.json);

    mkPackages = pkgs: let
      herdr-core = pkgs.callPackage ./core.nix {
        inherit (versions.core) version;
        hash = versions.core.hashes.${pkgs.stdenv.hostPlatform.system};
      };
      herdr-app = pkgs.callPackage ./app.nix {
        inherit herdr-core;
        inherit (versions.app) version;
        hash = versions.app.hashes.${pkgs.stdenv.hostPlatform.system};
      };
    in {
      default = herdr-app;
      inherit herdr-app herdr-core;
    };
  in {
    packages = nixpkgs.lib.genAttrs systems (system: mkPackages (import nixpkgs {inherit system;}));

    overlays.default = final: prev:
      nixpkgs.lib.optionalAttrs final.stdenv.hostPlatform.isLinux (mkPackages final);

    nixosModules.default = {
      pkgs,
      lib,
      ...
    }: {
      # Herdr renders with Vulkan (and EGL); on NixOS the drivers come from
      # hardware.graphics.
      hardware.graphics.enable = lib.mkDefault true;

      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-app
        self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-core
      ];
    };

    homeModules.default = {pkgs, ...}: {
      home.packages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-app
        self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-core
      ];
    };

    homeManagerModules = self.homeModules;
  };
}
