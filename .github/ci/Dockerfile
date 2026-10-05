# CI env for Bubbles: stock Arch + the CachyOS noctalia-qs binary the shell
# targets, plus the Qt6 tooling (qmlformat/qmllint), fish (workflow shell) and
# nodejs (the .mjs unit tests). The image is rebuilt weekly by this workflow.
FROM archlinux:latest

RUN pacman -Sy --noconfirm --needed archlinux-keyring && \
    pacman -Syu --noconfirm --needed fish nodejs qt6-declarative qt6-5compat diffutils jq curl git && \
    pacman-key --init && \
    pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com && \
    pacman-key --lsign-key F3B607488DB35A47 && \
    pacman -U --noconfirm \
      'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-keyring-20240331-1-any.pkg.tar.zst' \
      'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-mirrorlist-27-1-any.pkg.tar.zst' && \
    printf '[cachyos]\nInclude = /etc/pacman.d/cachyos-mirrorlist\n' >> /etc/pacman.conf && \
    pacman -Sy --noconfirm && \
    pacman -S --noconfirm --needed noctalia-qs && \
    pacman -Scc --noconfirm
