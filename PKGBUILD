# Maintainer: gr1nch3
#
# Run `makepkg -i` from within this directory to build and install.

pkgname=quickshell-bubbles
pkgver=1.0.0
pkgrel=1
pkgdesc="Bubbles - Dynamic Island shell (Wayland/Quickshell)"
arch=('any')
url="https://github.com/gr1nch3/dotfiles"
license=('MIT')
depends=(
  'quickshell'
  'wf-recorder'
  'slurp'
  'grim'
  'cava'
  'playerctl'
  'awww'
  'matugen-bin'
  'networkmanager'
  'network-manager-applet'
  'blueman'
  'brightnessctl'
  'pulseaudio-utils'
  'wl-clipboard'
  'python'
)
optdepends=('sddm: SDDM greeter theme')
source=()
sha256sums=('SKIP')

package() {
  install -dm755 "${pkgdir}/etc/xdg/quickshell/bubbles"
  cp -r shell/. "${pkgdir}/etc/xdg/quickshell/bubbles/"

  # SDDM greeter: self-contained theme dir — the shared identity components
  # (Eye.qml, Mouth.qml) are copied in so imports resolve. a+rX everywhere:
  # sddm runs unprivileged and silently falls back to its embedded theme on
  # an unreadable file.
  _sddm="${pkgdir}/usr/share/sddm/themes/bubbles"
  install -dm755 "${_sddm}"
  for f in metadata.desktop theme.conf Main.qml AccountSwitcher.qml; do
    install -m644 "sddm-theme/${f}" "${_sddm}/${f}"
  done
  install -m644 shell/eyes/Eye.qml shell/eyes/Mouth.qml "${_sddm}/"
  chmod -R a+rX "${_sddm}"

  install -dm755 "${pkgdir}/usr/bin"
  cat > "${pkgdir}/usr/bin/bubbles" << 'EOF'
#!/usr/bin/env sh
exec qs -c bubbles "$@"
EOF
  chmod 755 "${pkgdir}/usr/bin/bubbles"
}

post_install() {
  cat <<EOF
==> To use the Bubbles greeter, set in /etc/sddm.conf.d/ (create if needed):
      [Theme]
      Current=bubbles
EOF
}
