{
  lib,
  stdenv,
  fetchurl,
  pname ? "herdr-core",
  version,
  hash,
}: let
  target = {
    x86_64-linux = "linux-x86_64";
    aarch64-linux = "linux-aarch64";
  }.${stdenv.hostPlatform.system};
in
  stdenv.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://releases.herdr.dev/core/${version}/${pname}-${target}.tar.gz";
      inherit hash;
    };

    # The tarball unpacks its files at the root, with no top-level directory.
    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      install -Dm755 herdr-core $out/bin/herdr-core
      ln -s herdr-core $out/bin/hc
      install -Dm644 LICENSE $out/share/licenses/herdr-core/LICENSE
      install -Dm644 THIRD-PARTY-NOTICES $out/share/licenses/herdr-core/THIRD-PARTY-NOTICES

      runHook postInstall
    '';

    meta = {
      description = "herdr-core (hc): terminals for coding agents that keep running";
      homepage = "https://herdr.dev";
      license = lib.licenses.asl20;
      mainProgram = "herdr-core";
      platforms = [ "x86_64-linux" "aarch64-linux" ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  }
