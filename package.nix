{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, libarchive
, zstd

, coreutils
, glibc
, freetype
, lame
, libidn
, speex
, v4l-utils
, xorg
, libxkbcommon
, alsa-lib
, hunspell
, gsl
, openblas
, blas
, libva
, opencv
, c-ares
, avahi
, avahi-compat
, nss
, nspr
, libpulseaudio
, speexdsp
, dbus
, glib
, krb5
, libdrm
, double-conversion
, gtk3
, lsb-release
, lshw
, procps
, systemd
, inetutils
, zlib
, libGL
, fontconfig
, udev
}:

let
  pname = "trueconf-client";
  version = "8.5.0.3260";

  # External libraries we might need to expose to the upstream binaries
  runtimeLibs = [
    glibc
    stdenv.cc.cc.lib
    freetype
    lame
    libidn
    speex
    v4l-utils
    xorg.libXext
    xorg.libX11
    xorg.libxcb
    xorg.libXrandr
    xorg.libXdamage
    xorg.libXcomposite
    xorg.libXtst
    xorg.libXScrnSaver
    xorg.libXcursor
    xorg.libXrender
    xorg.libXfixes
    xorg.libXi
    libxkbcommon
    alsa-lib
    hunspell
    gsl
    openblas
    blas
    libva
    opencv
    c-ares
    avahi
    avahi-compat
    nss
    nspr
    libpulseaudio
    speexdsp
    dbus
    glib
    krb5
    libdrm
    double-conversion
    gtk3
    zlib
    libGL
    fontconfig
    udev
    xorg.xcbutilwm
    xorg.xcbutilkeysyms
    xorg.xcbutilimage
    xorg.xcbutilrenderutil
  ];

  runtimeBins = [
    coreutils
    lsb-release
    lshw
    procps
    systemd
    inetutils
  ];
in

stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    # Upstream Debian package, version in query parameter
    url = "https://trueconf.com/download/client/linux/trueconf_client_debian13_amd64.deb?v=${version}";
    hash = "sha256-0Su/G61Djs6hdBKMrrRQIRDZvlApYF5qNLy1bRNERMQ=";
  };

  dontUnpack = true;
  strictDeps = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    libarchive
    zstd
  ];

  buildInputs = runtimeLibs;

  autoPatchelfIgnoreMissingDeps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$TMPDIR/extract"
    bsdtar -C "$TMPDIR/extract" -xf "$src"
    bsdtar -C "$TMPDIR/extract" -xf "$TMPDIR/extract/data.tar.gz"

    mkdir -p "$out"

    if [ -d "$TMPDIR/extract/opt" ]; then
      cp -r --preserve=mode -T "$TMPDIR/extract/opt" "$out/opt"
    fi

    # Probably ok to delete this but too lazy to test
    for d in applications icons metainfo pixmaps; do
      if [ -d "$TMPDIR/extract/usr/share/$d" ]; then
        mkdir -p "$out/share/$d"
        cp -r --preserve=mode "$TMPDIR/extract/usr/share/$d/"* "$out/share/$d/"
      fi
    done

    mkdir -p "$out/bin"
    target="$out/opt/trueconf/client/trueconf"
    [ -x "$out/opt/trueconf/client/TrueConf" ] && target="$out/opt/trueconf/client/TrueConf"
    if [ -f "$out/opt/trueconf/client/qt5/libexec/QtWebEngineProcess" ]; then
      chmod 0755 "$out/opt/trueconf/client/qt5/libexec/QtWebEngineProcess" || true
    fi

    # It does work with wayland but segfaults often, so I force x11 for now
    makeWrapper "$target" "$out/bin/trueconf" \
      --set-default QT_QPA_PLATFORM "xcb" \
      --set XDG_SESSION_TYPE "x11" \
      --prefix LD_LIBRARY_PATH : "$out/opt/trueconf/client/lib:$out/opt/trueconf/client/qt5/lib:${lib.makeLibraryPath runtimeLibs}" \
      --set LD_PRELOAD "${openblas}/lib/libopenblas.so.0" \
      --prefix PATH : "${lib.makeBinPath runtimeBins}" \
      --set QT_STYLE_OVERRIDE "" \
      --set QTWEBENGINEPROCESS_PATH "$out/opt/trueconf/client/qt5/libexec/QtWebEngineProcess" \
      --set QTWEBENGINE_DISABLE_SANDBOX "1" \
      --set QT_PLUGIN_PATH "$out/opt/trueconf/client/qt5/plugins" \
      --set QML2_IMPORT_PATH "$out/opt/trueconf/client/qt5/qml" \
      --prefix XDG_DATA_DIRS : "$out/share" \
      --run 'if [ -z "$PULSE_SERVER" ]; then if [ -n "$XDG_RUNTIME_DIR" ] && [ -S "$XDG_RUNTIME_DIR/pulse/native" ]; then export PULSE_SERVER="unix:$XDG_RUNTIME_DIR/pulse/native"; elif [ -S "/run/user/$(id -u)/pulse/native" ]; then export PULSE_SERVER="unix:/run/user/$(id -u)/pulse/native"; fi; fi'

    runHook postInstall
  '';

  meta = with lib; {
    description = "TrueConf for Linux — video conferencing client";
    homepage = "https://trueconf.com";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "trueconf";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}


