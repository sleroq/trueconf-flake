# TrueConf client (Nix flake)

Repackages the upstream TrueConf Linux client (Debian build) for Nix/NixOS.
Includes a wrapper, desktop entry, and icons.

## Install (flake)

- Run directly:
  ```bash
  nix run github:sleroq/trueconf-flake
  ```

- <details>
  <summary>Show NixOS system and Home Manager instructions</summary>

  ### NixOS system flake (environment.systemPackages)

  ```nix
  {
    inputs.trueconf-flake.url = "github:sleroq/trueconf-flake";

    outputs = { self, nixpkgs, trueconf-flake, ... }:
      let
        system = "x86_64-linux";
      in {
        nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            {
              # Required because this package is unfree
              nixpkgs.config.allowUnfree = true;

              environment.systemPackages = [
                trueconf-flake.packages.${system}.trueconf-client
              ];
            }
          ];
        };
      };
  }
  ```

</details>

## Audio

Tested with PipeWire (PulseAudio compatibility). Should also work with
PulseAudio if it provides a Pulse socket. The wrapper uses an existing Pulse
socket and does not start a PulseAudio daemon.

## Desktop

Installs a `.desktop` entry and icons; after installation they should appear in
most desktops (e.g. GNOME/KDE) under your applications menu.

## Disclaimer

I am not affiliated, associated, authorized, endorsed by, or in any way
officially connected with TrueConf. TrueConf and related names, marks, emblems
and images are registered trademarks of their respective owners. This package
repackages upstream binaries and is subject to TrueConf’s license terms.
