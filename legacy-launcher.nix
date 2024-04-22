{ stdenv, lib
, buildFHSUserEnv
, writeShellScript
, fetchurl
, jre
, jre8
, udev
, libGL
, libglvnd
, xorg
, flite
, libpulseaudio
}:

let
  pname = "legacy-launcher";
  version = "0.0.1";
  
  #
  javaRuntime = jre8;

  meta = with lib; {
    description = "Legacy Launcher Unofficial";
    homepage = "https://tlaun.ch";
    platforms = platforms.linux;
    license = licenses.unfree;
  };

  xorgLibs = with xorg; [
    libX11
    libXext
    libXcursor
    libXrandr
    libXxf86vm
    libpulseaudio
    libGL
  ];

  legacy-launcher = stdenv.mkDerivation (self: {
    inherit pname version meta;

    src = fetchurl {
      url = "https://llaun.ch/jar";
      hash = "sha256-3y0lFukFzch6aOxFb4gWZKWxWLqBCTQlHXtwp0BnlYg=";
    };

    dontBuild = true;
    dontConfigure = true;
    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/opt
      cp $src $out/opt/Legacy.jar

      runHook postInstall
    '';
  });
in buildFHSUserEnv {
  inherit meta;
  name = pname;

  targetPkgs = pkgs: [
    legacy-launcher
    
    jre
    jre8
    udev
    flite
  ] ++ xorgLibs;

  runScript = writeShellScript "legacy-launcher" ''
    cd ${legacy-launcher}
    java -jar /opt/Legacy.jar
  '';
}
