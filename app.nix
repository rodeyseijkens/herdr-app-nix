{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  addDriverRunpath,
  libxcb,
  libxkbcommon,
  wayland,
  libGL,
  vulkan-loader,
  herdr-core,
  pname ? "herdr-app",
  version,
  hash,
}: let
  target = {
    x86_64-linux = "linux-x86_64";
    aarch64-linux = "linux-aarch64";
  }.${stdenv.hostPlatform.system};

  runtimeLibs = [
    libxcb
    libxkbcommon
    wayland
    libGL
    vulkan-loader
  ];
in
  stdenv.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://releases.herdr.dev/app/${version}/${pname}-${target}.tar.gz";
      inherit hash;
    };

    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = [
      stdenv.cc.cc.lib
      libxcb
      libxkbcommon
    ];

    installPhase = ''
      runHook preInstall

      install -Dm755 herdr-app $out/bin/herdr-app
      install -Dm644 herdr-app.svg $out/share/icons/hicolor/scalable/apps/herdr-app.svg
      install -Dm644 LICENSE $out/share/licenses/herdr-app/LICENSE
      install -Dm644 THIRD-PARTY-NOTICES $out/share/licenses/herdr-app/THIRD-PARTY-NOTICES
      install -Dm644 ${./herdr-app.desktop} $out/share/applications/herdr-app.desktop

      runHook postInstall
    '';

    postFixup = ''
      # The SVG deliberately stays out of $out/bin: the app treats a folder
      # holding both the binary and herdr-app.svg as an install it may
      # self-update, and a Nix store path is read-only.
      wrapProgram $out/bin/herdr-app \
        --prefix PATH : ${lib.makeBinPath [ herdr-core ]} \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath ([ addDriverRunpath.driverLink ] ++ runtimeLibs)} \
        --prefix XDG_DATA_DIRS : ${addDriverRunpath.driverLink}/share
    '';

    meta = {
      description = "Terminals and coding agents that keep running";
      homepage = "https://herdr.dev";
      license = lib.licenses.asl20;
      mainProgram = "herdr-app";
      platforms = [ "x86_64-linux" "aarch64-linux" ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  }
