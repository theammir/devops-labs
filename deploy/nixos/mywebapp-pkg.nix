{ stdenv }:
stdenv.mkDerivation {
  pname = "mywebapp";
  version = "0.1.0";
  src = ./mywebapp-src;
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/mywebapp
    cp -r . $out/lib/mywebapp/
    runHook postInstall
  '';
}
