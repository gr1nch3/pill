self: {
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.bubbles;
  pkg = self.packages.${pkgs.system}.default;
in {
  meta.maintainers = [];

  options.programs.bubbles = {
    enable = mkEnableOption "Bubbles Quickshell shell";

    package = mkOption {
      type = types.package;
      default = pkg;
      description = "Bubbles package to use";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      cfg.package
      playerctl
      cava
      wf-recorder
      slurp
      grim
      brightnessctl
      wl-clipboard
      python3
      jq
      imagemagick
      networkmanagerapplet
      blueman
      awww
      matugen
      pulseaudio # pactl (volume/device listing)
      power-profiles-daemon # powerprofilesctl (ControlCenter power tile)
    ];

    xdg.configFile."quickshell/bubbles".source =
      "${cfg.package}/etc/xdg/quickshell/bubbles";

    # No compositor wiring here: the user's own Hyprland config owns
    # exec-once + keybinds and consumes bubbles over IPC (see README).
  };
}
