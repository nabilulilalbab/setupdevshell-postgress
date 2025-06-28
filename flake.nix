{
  description = "Go + Postgres Final Dev Environment";

  inputs = {
    # Secara eksplisit menunjuk ke 'unstable' untuk paket termutakhir.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Memberitahu devshell & flake-utils untuk 'mengikuti' nixpkgs kita.
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, flake-utils, devshell, nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ devshell.overlays.default ];
        };
      in
      {
        devShells.default = pkgs.devshell.mkShell {
          imports = [ (pkgs.devshell.importTOML ./devshell.toml) ];
        };
      });
}

