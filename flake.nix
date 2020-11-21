{
  description = "The spodr website";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    mozilla = { url = "github:mozilla/nixpkgs-mozilla"; flake = false; };
  };

  outputs = { self, nixpkgs, flake-utils, mozilla }: flake-utils.lib.eachDefaultSystem (system:
    let pkgs = import nixpkgs {
      inherit system;
      overlays = [ (import "${mozilla}/rust-overlay.nix") ];
    }; in {
      devShell = pkgs.mkShell {
        buildInputs = [
          (pkgs.rustChannelOf {
            rustToolchain = ./rust-toolchain;
            # SHA256 of latest stable from https://static.rust-lang.org/dist/channel-rust-stable.toml.sha256
            sha256 = "69dac0a6249c186b78959bc6a448db5a26397b5d23b8e5518723694522d371c2";
          }).rust
        ];
      };
    });
}
