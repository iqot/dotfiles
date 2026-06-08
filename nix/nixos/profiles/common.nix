{
  lib,
  config,
  options,
  pkgs,
  ...
}:

let
  inherit (lib) mkDefault;
  inherit (config.dotfiles) flakeOptions;
  nixAttrName = flakeOptions.nix.package;
in
{
  config = {
    i18n.defaultLocale = mkDefault "en_US.UTF-8";
    console.keyMap = mkDefault "us";

    time.timeZone = mkDefault "Pacific/Auckland";

    nix.package = mkDefault pkgs.nixVersions.${nixAttrName};
    nix.extraOptions = ''
      experimental-features = nix-command flakes
    '';
    nix.settings = {
      substituters = [ "https://ryoppippi.cachix.org" ];
      trusted-public-keys = [ "ryoppippi.cachix.org-1:b2LbtWNvJeL/qb1B6TYOMK+apaCps4SCbzlPRfSQIms=" ];
    };
  };
}
