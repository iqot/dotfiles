{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.profiles.laptop;
in
{
  options.dotfiles.profiles.laptop = {
    enable = lib.mkEnableOption "Configuration for laptops.";
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth.enable = lib.mkDefault true;
    hardware.trackpoint.emulateWheel = lib.mkDefault true;

    dotfiles.profiles = {
      desktop.enable = lib.mkDefault true;
      hardware.enable = lib.mkDefault true;
    };

    services.xserver.xkb.options = lib.mkDefault "ctrl:nocaps,shift:both_capslock";
    services.libinput.touchpad = {
      clickMethod = lib.mkDefault "clickfinger";
      naturalScrolling = lib.mkDefault true;
      tapping = lib.mkDefault false;
    };
    services.xserver = {
      synaptics = {
        tapButtons = lib.mkDefault false;
        twoFingerScroll = lib.mkDefault true;
        horizEdgeScroll = lib.mkDefault false;
        vertEdgeScroll = lib.mkDefault false;
        palmDetect = lib.mkDefault true;
      };
    };
  };
}
