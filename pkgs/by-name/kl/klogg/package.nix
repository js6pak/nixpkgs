{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  fetchzip,
  libsForQt5,
  cmake,
  git,
  python3,
  util-linux,
  boost,
  ragel,
}:

stdenv.mkDerivation rec {
  pname = "klogg";
  version = "22.06";
  subversion = "0.1289";

  src = fetchFromGitHub {
    owner = "variar";
    repo = "klogg";
    tag = "v${version}";
    sha256 = "sha256-RXISwpQKY9ZLoIGIEpvsXfWIIvtn98mXror39Ko/OZs=";
  };

  patches = [
    (fetchpatch {
      url = "https://aur.archlinux.org/cgit/aur.git/plain/crash_handler.patch?h=klogg&id=a32a1632f2fdc5db167c928addb182d715af0275";
      hash = "sha256-hpywZwsGAwSvblCje4hQQOD8pM9Ld8NOSb8Q62skF+k=";
    })
    (fetchpatch {
      url = "https://aur.archlinux.org/cgit/aur.git/plain/qt6_karchive.patch?h=klogg&id=44002c04aba5839af05dea38c70072010da7e76b";
      hash = "sha256-KCeOoVfLitHjOdhFSYWNx5jnhMMUJZ3ynXi/1VvuWkE=";
    })
  ];

  cpm = fetchzip {
    url = "https://github.com/variar/klogg/releases/download/v${version}/klogg-${version}.${subversion}.deps.tar.gz";
    hash = "sha256-aCV7GA9yT+FUiqtbNPkA6HxKa1B9NXOJVdd+gURQ+Ao=";
  };

  prePatch = ''
    cp -R "${cpm}" "/build/cpm_cache"
    chmod -R u+w "/build/cpm_cache"
  '';

  nativeBuildInputs = [
    libsForQt5.wrapQtAppsHook
    cmake
    git
    python3
    util-linux
  ];

  buildInputs = [
    libsForQt5.qtbase
    boost
    ragel
  ];

  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.10")

    (lib.cmakeFeature "KLOGG_VERSION" "${version}.${subversion}")
    (lib.cmakeBool "KLOGG_BUILD_TESTS" false)
    (lib.cmakeBool "KLOGG_GENERIC_CPU" true)
    (lib.cmakeBool "CPM_USE_LOCAL_PACKAGES" true)
    (lib.cmakeFeature "CPM_SOURCE_CACHE" "/build/cpm_cache")
  ];

  meta = with lib; {
    description = "Really fast log explorer based on glogg project";
    mainProgram = "klogg";
    longDescription = ''
      A multi-platform GUI application to browse and search through long or complex log files. It is designed with programmers and system administrators in mind. glogg can be seen as a graphical, interactive combination of grep and less.
    '';
    homepage = "https://klogg.filimonov.dev/";
    license = licenses.gpl3Plus;
    platforms = platforms.unix;
    maintainers = with maintainers; [ js6pak ];
  };
}
