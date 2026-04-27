{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.profiles.network;
  hasInteractiveCfg = config.dotfiles.profiles.interactive.enable;
in
{
  options.dotfiles.profiles.network = {
    enable = lib.mkEnableOption "collection of network configurations";
    tailscale.enable = lib.mkEnableOption "Tailscale VPN";
  };

  config = lib.mkIf cfg.enable {
    networking = {
      firewall = {
        enable = lib.mkDefault true;
        allowPing = lib.mkDefault false;
        trustedInterfaces = lib.mkIf cfg.tailscale.enable [ "tailscale0" ];
        allowedUDPPorts = lib.mkIf cfg.tailscale.enable [ config.services.tailscale.port ];
      };

      # container networking
      nat = {
        enable = lib.mkDefault true;
        internalInterfaces = [ "ve-+" ];
        externalInterface = lib.mkDefault "eno1";
      };

      networkmanager = {
        enable = lib.mkDefault true;
        unmanaged = [ "interface-name:ve-*" ];
      };
    };

    services.avahi = {
      enable = lib.mkDefault true;
      nssmdns4 = lib.mkDefault true;
      publish.enable = lib.mkDefault true;
      publish.addresses = lib.mkDefault true;
    };

    services.openssh = lib.mkIf hasInteractiveCfg {
      enable = lib.mkDefault true;
      startWhenNeeded = lib.mkDefault true;
      settings = {
        PasswordAuthentication = lib.mkDefault false;
        PermitRootLogin = lib.mkDefault "no";
      };
    };

    services.tailscale = lib.mkIf cfg.tailscale.enable {
      enable = true;
    };
  };
}
