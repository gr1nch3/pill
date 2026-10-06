{
  lib,
  stdenv,
  quickshell,
}:

stdenv.mkDerivation {
  pname = "pill";
  version = "1.0.0";

  src = ./..;

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/etc/xdg/quickshell
    cp -r shell $out/etc/xdg/quickshell/pill

    mkdir -p $out/bin
    cat > $out/bin/pill << 'WRAPPER'
    #!${stdenv.shell}
    exec ${lib.getExe quickshell} -c pill --path $out/etc/xdg/quickshell/pill "$@"
    WRAPPER
    chmod 755 $out/bin/pill
  '';

  meta = {
    description = "Pill - Dynamic Island shell (Wayland/Quickshell)";
    longDescription = ''
      A Quickshell-based Dynamic Island shell with Material You theming,
      media controls, system stats, notifications, screen recording,
      session lock, and more.
    '';
    homepage = "https://github.com/gr1nch3/dotfiles";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = [];
    mainProgram = "pill";
  };
}
