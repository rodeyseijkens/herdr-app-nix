# Herdr for NixOS

Unofficial Nix package for [Herdr](https://herdr.dev), the desktop app for
terminals and coding agents. It packages the prebuilt Linux releases of
`herdr-app` and its companion `herdr-core` (`hc`) for x86-64 and ARM64.

This is the desktop app from
[herdrdev/herdr-app](https://github.com/herdrdev/herdr-app), not the terminal
multiplexer packaged as `herdr` in nixpkgs.

## Installation

### NixOS (Recommended)

Add the flake input and import the module:

```nix
{
  inputs = {
    herdr = {
      url = "github:rodeyseijkens/herdr-app-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, herdr, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        herdr.nixosModules.default
        # ... your other modules
      ];
    };
  };
}
```

The module:

- Enables `hardware.graphics` (Vulkan/EGL drivers are required)
- Adds `herdr-app` and `herdr-core` (including `hc`) to system packages

`herdr-app` is wrapped with `herdr-core` on its `PATH`, so the app always finds
the packaged core. The app detects a package-managed core and leaves it alone.

### Home Manager

```nix
{
  inputs = {
    herdr = {
      url = "github:rodeyseijkens/herdr-app-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, herdr, home-manager, ... }: {
    homeConfigurations.myhost = home-manager.lib.homeManagerConfiguration {
      modules = [
        herdr.homeModules.default
        # ... your other modules
      ];
    };
  };
}
```

Or add the packages manually:

```nix
home.packages = [
  herdr.packages.x86_64-linux.herdr-app
  herdr.packages.x86_64-linux.herdr-core
];
```

### Overlay

```nix
{
  nixpkgs.overlays = [ herdr.overlays.default ];
  environment.systemPackages = with pkgs; [
    herdr-app
    herdr-core
  ];
}
```

### Direct Run (no install)

```bash
nix run github:rodeyseijkens/herdr-app-nix#herdr-app
```

### Imperative Install

```bash
nix profile install github:rodeyseijkens/herdr-app-nix#herdr-app
nix profile install github:rodeyseijkens/herdr-app-nix#herdr-core
```

## Updates

Upstream publishes a single release channel at
`releases.herdr.dev`; there is no nightly. The packaged app does not
self-update (the release tar is unpacked into the read-only Nix store), and
the packaged core is detected as package-managed. Update both by updating
the flake input:

```bash
nix flake update herdr
```

Maintainers can refresh the pinned versions and hashes for both packages:

```bash
./update.sh
```

The GitHub Actions workflow runs this every six hours, builds the result, and
tags a release when `herdr-app` changes.

## Notes

- Linux only, x86-64 and ARM64.
- Herdr needs a working Vulkan driver and a desktop session. On NixOS that
  means `hardware.graphics.enable = true`, which the module sets by default.
- Wayland and X11 are both supported by the upstream build.
- The app and core are Apache-2.0 binaries downloaded from the official
  release bucket.

## License

The Nix packaging is MIT. Herdr itself is Apache-2.0.

## Links

- [Herdr](https://herdr.dev)
- [Herdr app GitHub](https://github.com/herdrdev/herdr-app)
- [Herdr core GitHub](https://github.com/herdrdev/herdr-core)
