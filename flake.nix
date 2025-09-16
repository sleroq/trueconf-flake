{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    devShells.x86_64-linux.default = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "intel-media-sdk-23.2.2" ];
        };
      };
    in pkgs.mkShell {
      packages = [
        pkgs.nixfmt-rfc-style
      ];
    };
    packages.x86_64-linux = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "intel-media-sdk-23.2.2" ];
        };
      };
    in {
      trueconf-client = pkgs.callPackage ./package.nix {};
      default = (pkgs.callPackage ./package.nix {});
    };
  };
}
