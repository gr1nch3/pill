self: quickshellFor: {
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.pill;
  pkg = self.packages.${pkgs.system}.default;
  quickshell = quickshellFor pkgs.system;
in {
  meta.maintainers = [];

  options.programs.pill = {
    enable = mkEnableOption "Pill Quickshell shell";

    package = mkOption {
      type = types.package;
      default = pkg;
      description = "Pill package to use";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      cfg.package
      quickshell # `qs -c pill -d` (README's start command)
      playerctl
      cava
      wf-recorder
      slurp
      grim
      brightnessctl
      wl-clipboard
      cliphist
      glib
      xdg-utils
      jq
      imagemagick
      ffmpeg
      networkmanagerapplet
      blueman
      awww
      wallust
      pulseaudio # pactl (volume/device listing)
      power-profiles-daemon # powerprofilesctl (ControlCenter power tile)
    ];

    xdg.configFile."quickshell/pill".source =
      "${cfg.package}/etc/xdg/quickshell/pill";

    # No compositor wiring here: the user's own Hyprland config owns
    # exec-once + keybinds and consumes pill over IPC (see README).
  };
}
