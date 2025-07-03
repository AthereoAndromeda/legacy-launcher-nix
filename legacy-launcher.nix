{
  stdenv,
  lib,
  makeDesktopItem,
  copyDesktopItems,
  ll-hash ? "sha256-C3NBjYEHnrtTwEVmFkcKQqVr/9/fXoKSQG8Hs2EwbNg=",
  javaRuntimes ? [jre jre8],
  writeShellScript,
  fetchurl,
  curl,
  systemd,
  alsa-lib,
  jre,
  jre8,
  libGL,
  libglvnd,
  xorg,
  flite,
  libpulseaudio,
  # lib
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  pango,
  gtk3-x11,
  gtk2-x11,
  nspr,
  nss,
  zlib,
  libuuid,
  makeWrapper,
  makeBinaryWrapper,
  wrapGAppsHook3,
  gobject-introspection,
  unzip,
  # autoPatchelfHook,
  glfw3-minecraft,
  openal,
  libjack2,
  pipewire,
}: let
  pname = "legacy-launcher";
  version = "0.0.1";

  icon = ./assets/ll-icon.svg;

  runtimeLibs = [
    ## native versions
    glfw3-minecraft
    openal

    ## openal
    alsa-lib
    libjack2
    libpulseaudio
    pipewire

    ## glfw
    libGL
    libX11
    libXcursor
    libXext
    libXrandr
    libXxf86vm

    udev # oshi

    vulkan-loader # VulkanMod's lwjgl
  ];

  xorgLibs = with xorg; [
    libXxf86vm
    libpulseaudio
    libGL
  ];

  # cheack https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/pr/prismlauncher-unwrapped/package.nix

  envLibPathMod = [
    curl
    libpulseaudio
    systemd
    alsa-lib # needed for narrator
    flite # needed for narrator
    xorg.libXxf86vm # needed only for versions <1.13
  ];
  envLibPath = lib.makeLibraryPath envLibPathMod;

  libPath = lib.makeLibraryPath (
    [
      alsa-lib
      atk
      cairo
      cups
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      pango
      gtk3-x11
      gtk2-x11
      nspr
      nss
      stdenv.cc.cc
      zlib
      libuuid
    ]
    ++ (with xorg; [
      libX11
      libxcb
      libXcomposite
      libXcursor
      libXdamage
      libXext
      libXfixes
      libXi
      libXrandr
      libXrender
      libXtst
      libXScrnSaver
    ])
    ++ envLibPathMod
  );

  libs = libPath ++ envLibPath;
in
  stdenv.mkDerivation {
    inherit pname version;

    nativeBuildInputs = [
      makeBinaryWrapper
      wrapGAppsHook3
      copyDesktopItems
      gobject-introspection
      unzip
    ];

    buildInputs =
      [
        flite
      ]
      ++ xorgLibs;

    src = fetchurl {
      url = "https://llaun.ch/jar";
      hash = ll-hash;
    };

    dontBuild = true;
    dontConfigure = true;
    dontUnpack = true;
    dontWrapGApps = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/{opt,bin}
      # cp $src $out/opt/Legacy.jar
      makeWrapper ${jre}/bin/java $out/bin/legacy-launcher \
        --add-flags "-jar $src" \
        --prefix LD_LIBRARY_PATH : ${libPath} \
        --prefix PATH : ${lib.makeBinPath javaRuntimes} \
        --set JAVA_HOME ${lib.getBin jre} \
        --chdir /tmp \
        "''${gappsWrapperArgs[@]}"

      # add symlinks to JRE to make switching to them easier
      # ln -s ${jre8} $out/opt/java8

      runHook postInstall
    '';

    postInstall = ''
      mkdir -p $out/share/{applications,/share/icons/hicolor/scalable/apps/}
      install -Dm444 ${icon} $out/share/icons/hicolor/scalable/apps/${pname}.svg
    '';

    # preFixup = ''
    #   patchelf \
    #     --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
    #     --set-rpath '$ORIGIN/'":${libPath}" \
    #     $out/opt/Legacy.jar
    # '';

    # postFixup = ''
    #   # Do not create `GPUCache` in current directory
    #   makeWrapper $out/opt/Legacy.jar $out/bin/legacy-launcher \
    #     --prefix LD_LIBRARY_PATH : ${envLibPath} \
    #     --prefix PATH : ${lib.makeBinPath javaRuntimes} \
    #     --set JAVA_HOME ${lib.getBin jre} \
    #     --chdir /tmp \
    #     "''${gappsWrapperArgs[@]}"
    # '';

    desktopItems = [
      (makeDesktopItem {
        name = pname;
        desktopName = "Legacy Launcher";
        exec = "legacy-launcher";
        icon = "legacy-launcher";
        comment = "A Minecraft Client";
        categories = ["Game"];
      })
    ];

    meta = with lib; {
      description = "Legacy Launcher Unofficial";
      homepage = "https://tlaun.ch";
      mainProgram = "legacy-launcher";
      platforms = platforms.linux;
      license = licenses.unfree;
    };
  }
