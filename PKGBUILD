# Maintainer: gr1nch3
#
# Run `makepkg -i` from within this directory to build and install.

pkgname=quickshell-bubbles
pkgver=1.0.0
pkgrel=1
pkgdesc="Bubbles - Dynamic Island shell (Wayland/Quickshell)"
arch=('any')
url="https://github.com/gr1nch3/bubbles"
license=('MIT')
depends=(
  'quickshell'
  'wf-recorder'
  'slurp'
  'grim'
  'cava'
  'playerctl'
  'awww'
  'wallust'
  'networkmanager'
  'network-manager-applet'
  'blueman'
  'brightnessctl'
  'libpulse'
  'wl-clipboard'
  'python'
)
optdepends=('sddm: SDDM greeter theme')
source=()
sha256sums=()

package() {
  install -dm755 "${pkgdir}/etc/xdg/quickshell/bubbles"
  cp -r "$startdir/shell/." "${pkgdir}/etc/xdg/quickshell/bubbles/"

  # SDDM greeter: self-contained theme dir — the shared identity component
  # (Eye.qml) is copied in so imports resolve. a+rX everywhere: sddm runs
  # unprivileged and silently falls back to its embedded theme on an
  # unreadable file.
  _sddm="${pkgdir}/usr/share/sddm/themes/bubbles"
  install -dm755 "${_sddm}"
  for f in metadata.desktop theme.conf Main.qml TextAction.qml; do
    install -m644 "$startdir/sddm-theme/${f}" "${_sddm}/${f}"
  done
  install -m644 "$startdir/shell/eyes/Eye.qml" "${_sddm}/"
  install -m644 "$startdir/shell/components/PatternBackground.qml" "${_sddm}/"
  chmod -R a+rX "${_sddm}"

  install -Dm755 "$startdir/bin/bubbles" "${pkgdir}/usr/bin/bubbles"
}

post_install() {
  cat <<EOF
==> To use the Bubbles greeter, set in /etc/sddm.conf.d/ (create if needed):
      [Theme]
      Current=bubbles

    Then run 'bubbles theme <name>' once and approve the polkit prompt to push
    the current palette to the greeter (bubbles update does it too).
EOF
}
