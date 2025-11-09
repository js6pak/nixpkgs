{
  lib,
  stdenvNoCC,
  fetchzip,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  libgcc,
  wayland,
  xorg,
  fontconfig,
  libGL,
  libsecret,
  jetbrains,
  undmg,
}:

let
  pname = "jetbrains-toolbox";
  version = "3.0.1.59888";

  updateScript = ./update.sh;

  meta = {
    description = "JetBrains Toolbox";
    homepage = "https://www.jetbrains.com/toolbox-app";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ ners js6pak ];
    platforms = [
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-linux"
      "x86_64-darwin"
    ];
    mainProgram = "jetbrains-toolbox";
  };

  selectSystem =
    let
      inherit (stdenvNoCC.hostPlatform) system;
    in
    attrs: attrs.${system} or (throw "Unsupported system: ${system}");

  selectKernel =
    let
      inherit (stdenvNoCC.hostPlatform.parsed) kernel;
    in
    attrs: attrs.${kernel.name} or (throw "Unsupported kernel: ${kernel.name}");

  selectCpu =
    let
      inherit (stdenvNoCC.hostPlatform.parsed) cpu;
    in
    attrs: attrs.${cpu.name} or (throw "Unsupported CPU: ${cpu.name}");

  sourceForVersion =
    version:
    let
      archSuffix = selectCpu {
        x86_64 = "";
        aarch64 = "-arm64";
      };
      hash = selectSystem {
        x86_64-linux = "sha256-+rSjKr/MF6WbRkXeCvxzepThiDleYdtqQmX8rfJinNs=";
        aarch64-linux = "sha256-Zt3OqnQhiK8nWrKYWFuQ10oc5SZJbhrLpGY5P0QcbBw=";
        x86_64-darwin = "sha256-Lbq+buoulHmLBNOm23yDBoodPPOOOfF/FfkdGEOh/N4=";
        aarch64-darwin = "sha256-jaLddShsw/lDIICAa8RZFhOoWJ7hx9gfRFwxy1t6sVc=";
      };
    in
    selectKernel {
      linux = fetchzip {
        url = "https://download-cdn.jetbrains.com/toolbox/jetbrains-toolbox-${version}${archSuffix}.tar.gz";
        inherit hash;
      };
      darwin = fetchurl {
        url = "https://download-cdn.jetbrains.com/toolbox/jetbrains-toolbox-${version}${archSuffix}.dmg";
        inherit hash;
      };
    };
in
selectKernel {
  linux = stdenvNoCC.mkDerivation {
    inherit pname version meta;

    src = sourceForVersion version;

    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
      copyDesktopItems
    ];

    buildInputs = [
      libgcc.lib
      wayland
      xorg.libX11
      xorg.libXext
      xorg.libXrender
      fontconfig
      libGL
      libsecret
    ];

    desktopItems = [
      (makeDesktopItem {
        name = "jetbrains-toolbox";
        desktopName = "JetBrains Toolbox";
        exec = "jetbrains-toolbox %u";
        icon = "jetbrains-toolbox";
        categories = [ "Development" ];
        mimeTypes = [ "x-scheme-handler/jetbrains" ];
        terminal = false;
      })
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/opt
      mv bin $out/opt/jetbrains-toolbox

      rm -r $out/opt/jetbrains-toolbox/jre
      ln -s "${jetbrains.jdk}/lib/openjdk" $out/opt/jetbrains-toolbox/jre

      patchelf $out/opt/jetbrains-toolbox/jetbrains-toolbox \
        --add-needed libsecret-1.so

      wrapProgram $out/opt/jetbrains-toolbox/jetbrains-toolbox \
        --add-flag "--update-failed"

      install -Dm0644 $out/opt/jetbrains-toolbox/toolbox-tray-color.png $out/share/pixmaps/jetbrains-toolbox.png

      mkdir -p $out/bin
      ln -s $out/opt/jetbrains-toolbox/jetbrains-toolbox $out/bin/jetbrains-toolbox

      runHook postInstall
    '';

    passthru = {
      inherit updateScript;
    };
  };

  darwin = stdenvNoCC.mkDerivation (finalAttrs: {
    inherit
      pname
      version
      meta
      ;

    src = sourceForVersion finalAttrs.version;

    nativeBuildInputs = [ undmg ];

    sourceRoot = "JetBrains Toolbox.app";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications $out/bin
      cp -r . $out/Applications/"JetBrains Toolbox.app"
      ln -s $out/Applications/"JetBrains Toolbox.app"/Contents/MacOS/jetbrains-toolbox $out/bin/jetbrains-toolbox

      runHook postInstall
    '';

    passthru = {
      inherit updateScript;
    };
  });
}
