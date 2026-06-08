{
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (config.dotfiles) flakeOptions;
  nixAttrName = flakeOptions.nix.package;
in
{
  # Setup Nix and the Nix daemon. After nix-darwin has been activated, it should
  # be safe to remove the copy of Nix from the default profile.
  #
  # $ sudo -H nix-channel --remove nixpkgs
  # $ sudo -H nix-env -e '*'
  nix.package = lib.mkDefault pkgs.nixVersions.${nixAttrName};
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  ''
  + lib.optionalString pkgs.stdenv.isAarch64 ''
    extra-platforms = aarch64-darwin x86_64-darwin
  '';
  nix.settings = {
    substituters = [ "https://ryoppippi.cachix.org" ];
    trusted-public-keys = [ "ryoppippi.cachix.org-1:b2LbtWNvJeL/qb1B6TYOMK+apaCps4SCbzlPRfSQIms=" ];
  };
}
