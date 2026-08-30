{ lib, stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "herdr";
  version = "0.8.2";

  src = fetchurl {
    url = "https://github.com/herdrdev/herdr/releases/download/v${finalAttrs.version}/herdr-linux-x86_64";
    hash = "sha256-l2FQoU1JDJSyQ+ouGn6y37Z/EuNrGC25CTb2co5q7PQ=";
  };

  dontUnpack = true;

  # A static PIE: no interpreter and no NEEDED entry, so there is nothing for
  # autoPatchelfHook to rewrite.
  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/herdr
    runHook postInstall
  '';

  meta = {
    description = "Session manager for coding agents";
    homepage = "https://github.com/herdrdev/herdr";
    platforms = [ "x86_64-linux" ];
    mainProgram = "herdr";
  };
})
