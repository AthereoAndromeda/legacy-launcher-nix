{
  stdenv,
  lib,
  javaRuntimes ? [jre jre8],
  buildFHSUserEnv,
  writeShellScript,
  fetchurl,
  jre,
  jre8,
  udev,
  libGL,
  libglvnd,
  xorg,
  flite,
  libpulseaudio,
}: let
  pname = "legacy-launcher";
  version = "0.0.1";

  xorgLibs = with xorg; [
    libX11
    libXext
    libXcursor
    libXrandr
    libXxf86vm
    libpulseaudio
    libGL
    libglvnd
  ];

  legacy-launcher = stdenv.mkDerivation (self: {
    inherit pname version;

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

      # add symlinks to JRE to make switching to them easier
      ln -s ${jre8} $out/opt/java8

      runHook postInstall
    '';
  });
in
  buildFHSUserEnv {
    name = pname;

    targetPkgs = pkgs:
      [
        legacy-launcher

        udev
        flite
      ]
      ++ xorgLibs
      ++ javaRuntimes;

    runScript = writeShellScript "legacy-launcher" ''
      cd ${legacy-launcher}
      java -jar /opt/Legacy.jar
    '';

    meta = with lib; {
      description = "Legacy Launcher Unofficial";
      homepage = "https://tlaun.ch";
      platforms = platforms.linux;
      license = licenses.unfree;
    };
  }
