{
  stdenv,
  lib,
  makeDesktopItem,
  ll-hash ? "sha256-C3NBjYEHnrtTwEVmFkcKQqVr/9/fXoKSQG8Hs2EwbNg=",
  buildFHSEnv,
  javaRuntimes ? [jre jre8],
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

  icon = ./ll.svg;

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
      hash = ll-hash;
    };

    dontBuild = true;
    dontConfigure = true;
    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/icons/hicolor/scalable/apps/
      install -Dm444 ${icon} $out/share/icons/hicolor/scalable/apps/${pname}.svg

      mkdir -p $out/opt
      cp $src $out/opt/Legacy.jar

      # add symlinks to JRE to make switching to them easier
      ln -s ${jre8} $out/opt/java8

      runHook postInstall
    '';

    desktopItems = [
      (makeDesktopItem {
        name = pname;
        desktopName = "Legacy Launcher";
        exec = "legacy-launcher";
        icon = "legacy-launcher";
        categories = ["Game"];
      })
    ];
  });
in
  buildFHSEnv {
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
      mainProgram = "legacy-launcher";
      platforms = platforms.linux;
      license = licenses.unfree;
    };
  }
