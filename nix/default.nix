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
    mkdir -p $out/bin $out/libexec $out/etc/xdg/quickshell
    cp -r shell $out/shell
    ln -s $out/shell $out/etc/xdg/quickshell/pill

    # The CLI (doctor/reload/theme/IPC). It locates the shell tree as
    # ../shell relative to itself, which this layout provides.
    install -Dm755 bin/pill $out/bin/pill-cli

    # A pinned `qs` for the CLI (IPC, reload, kill), ahead of whatever the
    # user has on PATH so the CLI always talks to the shell it shipped with.
    ln -s ${lib.getExe quickshell} $out/libexec/qs

    # Bare `pill` starts the shell (what `nix run` is for); anything with
    # arguments is a CLI command or an IPC call.
    cat > $out/bin/pill <<WRAPPER
#!${stdenv.shell}
set -eu
export PATH=${placeholder "out"}/libexec:\$PATH
if [ \$# -eq 0 ]; then
    exec ${lib.getExe quickshell} --path ${placeholder "out"}/shell
fi
exec ${placeholder "out"}/bin/pill-cli "\$@"
WRAPPER
    chmod 755 $out/bin/pill
  '';

  meta = {
    description = "Pill - Dynamic Island shell (Wayland/Quickshell)";
    longDescription = ''
      A Quickshell-based Dynamic Island shell with wallpaper-derived
      theming, media controls, system stats, notifications, screen
      recording, session lock, and more.
    '';
    homepage = "https://github.com/gr1nch3/pill";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = [];
    mainProgram = "pill";
  };
}
