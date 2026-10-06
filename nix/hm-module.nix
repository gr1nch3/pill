self: {
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.pill;
  pkg = self.packages.${pkgs.system}.default;
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
