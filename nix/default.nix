{
  lib,
  stdenv,
  quickshell,
}:

stdenv.mkDerivation {
  pname = "bubbles";
  version = "1.0.0";

  src = ./..;

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/etc/xdg/quickshell
    cp -r shell $out/etc/xdg/quickshell/bubbles

    mkdir -p $out/bin
    cat > $out/bin/bubbles << 'WRAPPER'
    #!${stdenv.shell}
    exec ${lib.getExe quickshell} -c bubbles --path $out/etc/xdg/quickshell/bubbles "$@"
    WRAPPER
    chmod 755 $out/bin/bubbles
  '';

  meta = {
    description = "Bubbles - Dynamic Island shell (Wayland/Quickshell)";
    longDescription = ''
      A Quickshell-based Dynamic Island shell with Material You theming,
      media controls, system stats, notifications, screen recording,
      session lock, and more.
    '';
    homepage = "https://github.com/gr1nch3/dotfiles";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = [];
    mainProgram = "bubbles";
  };
}
