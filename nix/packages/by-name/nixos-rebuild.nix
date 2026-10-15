{ nixos-rebuild, nix }:

# nixos-rebuild-ng ships a nix-update updateScript, but this package tracks the
# nixos flake input and can't be updated in-tree by the update app.
(nixos-rebuild.override { inherit nix; }).overrideAttrs (old: {
  passthru = builtins.removeAttrs old.passthru [ "updateScript" ];
})
