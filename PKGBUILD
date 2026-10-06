# Maintainer: gr1nch3
#
# Builds the tagged release tarball published by .github/workflows/release.yml.
# For the AUR: run `updpkgsums` after the matching GitHub release exists, then
# push PKGBUILD + .SRCINFO. Local checkout builds use the same tarball.

pkgname=pill
pkgver=1.0.0
pkgrel=1
pkgdesc="Pill - Dynamic Island shell (Wayland/Quickshell)"
arch=('any')
url="https://github.com/gr1nch3/pill"
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
source=("$pkgname-$pkgver.tar.gz::https://github.com/gr1nch3/pill/releases/download/v$pkgver/pill-v$pkgver.tar.gz")
sha256sums=('SKIP')

package() {
  local _src="$srcdir/pill-$pkgver"

  install -dm755 "${pkgdir}/etc/xdg/quickshell/pill"
  cp -r "$_src/shell/." "${pkgdir}/etc/xdg/quickshell/pill/"

  # SDDM greeter: self-contained theme dir — the shared identity component
  # (Eye.qml) is copied in so imports resolve. a+rX everywhere: sddm runs
  # unprivileged and silently falls back to its embedded theme on an
  # unreadable file.
  local _sddm="${pkgdir}/usr/share/sddm/themes/pill"
  install -dm755 "${_sddm}"
  for f in metadata.desktop theme.conf Main.qml TextAction.qml; do
    install -m644 "$_src/sddm-theme/${f}" "${_sddm}/${f}"
  done
  install -m644 "$_src/shell/eyes/Eye.qml" "${_sddm}/"
  install -m644 "$_src/shell/components/PatternBackground.qml" "${_sddm}/"
  chmod -R a+rX "${_sddm}"

  install -Dm755 "$_src/bin/pill" "${pkgdir}/usr/bin/pill"
}

post_install() {
  cat <<EOF
==> To use the Pill greeter, set in /etc/sddm.conf.d/ (create if needed):
      [Theme]
      Current=pill

    Then run 'pill theme <name>' once and approve the polkit prompt to push
    the current palette to the greeter (pill update does it too).
EOF
}
