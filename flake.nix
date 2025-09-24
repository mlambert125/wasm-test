{
  description = "Burn Bar development environment flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    fenix.url = "github:nix-community/fenix";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    fenix,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
      rust = with fenix.packages.${system};
        combine [
          stable.toolchain
          targets.wasm32-unknown-unknown.stable.rust-std
        ];
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          # languages / tooling
          rust
          nixd
          alejandra
          wasm-pack
        ];
      };
    });
}
