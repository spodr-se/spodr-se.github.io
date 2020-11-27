{
  description = "The spodr website";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    mozilla = { url = "github:mozilla/nixpkgs-mozilla"; flake = false; };
    import-cargo.url = "github:edolstra/import-cargo";
  };

  outputs = { self, nixpkgs, flake-utils, mozilla, import-cargo }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs {
            inherit system;
            overlays = [ (import "${mozilla}/rust-overlay.nix") ];
          };
          rust = (pkgs.rustChannelOf {
            rustToolchain = ./rust-toolchain;
            # SHA256 of latest stable from https://static.rust-lang.org/dist/channel-rust-stable.toml.sha256
            sha256 = "69dac0a6249c186b78959bc6a448db5a26397b5d23b8e5518723694522d371c2";
          }).rust;
          inherit (import-cargo.builders) importCargo; in
        rec {
          packages = {
            spodr-server = pkgs.stdenv.mkDerivation rec {
              name = "spodr-server";
              src = self;

              nativeBuildInputs = [
                # setupHook which makes sure that a CARGO_HOME with
                # vendored dependencies exists
                (importCargo { lockFile = ./Cargo.lock; inherit pkgs; }).cargoHome
                # Build-time dependencies
                rust
              ];

              buildPhase = ''
                cargo build --release --offline
              '';

              installPhase = ''
                install -Dm775 ./target/release/${name} $out/bin/${name}
              '';
            };

            container = pkgs.ociTools.buildContainer {
              args = [ "${packages.spodr-server}/bin/spodr-server" ];
            };
          };

          defaultPackage = packages.spodr-server;

          devShell = pkgs.mkShell {
            nativeBuildInputs = [ rust pkgs.postgresql_13 ];

            shellHook = ''
              export PGDATA="$PWD/db"
              if [ ! -d "$PGDATA" ]; then initdb --auth=trust --no-locale; fi
              sed --in-place "s|^#unix_socket_directories.*$|unix_socket_directories = '$PGDATA'|" \
                  "$PGDATA/postgresql.conf"

              trap "pg_ctl --pgdata='$PGDATA' stop" EXIT # Stop PostgreSQL upon exiting Nix shell
              pg_ctl --log="$PGDATA/postgres.log" start
            '';
          };
        });
}
