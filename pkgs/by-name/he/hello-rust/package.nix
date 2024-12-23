{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  name = "hello-rust";

  src = ./src;

  cargoLock.lockFile = ./src/Cargo.lock;

  meta = {
    description = "Basic sanity check that Rust infrastructure is working";
    platforms = lib.platforms.all;
    maintainers = [ ];
    mainProgram = "hello-rust";
  };

  # TODO why is this not added automatically?
  RUSTFLAGS = map (a: "-C link-arg=${a}") [
    "-lmcfgthread"
  ];

  auditable = false; # so I don't have to wait for cargo-auditable to build for mingw
}
