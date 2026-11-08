{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin system;
  cfg = config.dotfiles.profiles.t3code;

  # Every agent is pinned to an exact Nix binary so T3 Code never resolves it
  # through PATH, where a self-updating install could shadow the Nix build.
  # T3 Code rejects settings.json when an instance lacks `driver`.
  catalog = {
    # The development profile installs Claude wrapped with Node, which only
    # exists in the profile, so point at that rather than the bare package.
    claude.claudeAgent = {
      driver = "claudeAgent";
      displayName = "Claude";
      config.binaryPath = "${config.home.profileDirectory}/bin/claude";
    };
    # T3 Code drives Antigravity through Google's ACP server, not the `agy`
    # CLI. It expects `localharness_external` next to the executable, which
    # antigravity-acp provides; otherwise T3 Code downloads its own copy.
    antigravity.antigravity = {
      driver = "antigravity";
      displayName = "Antigravity";
      config.binaryPath = "${pkgs.antigravity-acp}/bin/agy_acp_server.par";
    };
    codex.codex = {
      driver = "codex";
      displayName = "Codex";
      config.binaryPath = lib.getExe inputs.codex-cli-nix.packages.${system}.codex;
    };
  };
in
{
  options.dotfiles.profiles.t3code = {
    enable = lib.mkEnableOption "T3 Code";

    providers = lib.mkOption {
      type = with lib.types; listOf (enum (lib.attrNames catalog));
      default = [ ];
      example = [
        "claude"
        "antigravity"
      ];
      description = ''
        Agents to register with T3 Code. Anything outside this catalog, such
        as company-specific endpoints, belongs in the machine's own
        {option}`programs.t3code.userSettings.providerInstances`.
      '';
    };

    mode = lib.mkOption {
      type = lib.types.enum [
        "desktop"
        "server"
      ];
      default = "desktop";
      description = ''
        `desktop` installs the app. `server` runs headless {command}`t3 serve`
        as a user service, bound to localhost on the default port.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(lib.elem "claude" cfg.providers) || config.dotfiles.profiles.development.enable;
        message = "dotfiles.profiles.t3code: the claude provider needs the development profile, which installs claude.";
      }
      {
        assertion = !(isDarwin && cfg.mode == "server");
        message = "dotfiles.profiles.t3code: server mode isn't supported on macOS, where the app comes from the t3-code Homebrew cask.";
      }
    ];

    programs.t3code = {
      enable = true;
      # On macOS the app comes from the t3-code Homebrew cask (osx branch), so
      # Nix only manages its settings.
      package = lib.mkIf isDarwin null;
      server = lib.mkIf (cfg.mode == "server") {
        enable = true;
        # Pin loopback explicitly. WSL forwards it to Windows' localhost, and
        # anything wider (e.g. --tailscale-serve) is opted into per machine.
        extraArgs = [
          "--host"
          "127.0.0.1"
        ];
      };

      # Match herdr-app, which uses Fira Code for both its terminal and UI.
      clientSettings = {
        fontFamilySans = "Fira Code";
        fontFamilyCode = "Fira Code";
        fontFamilyComposer = "Fira Code";
        fontFamilyTerminal = "Fira Code";
      };

      userSettings.providerInstances = lib.mkMerge (
        map (name: lib.mapAttrs (_: p: p // { enabled = true; }) catalog.${name}) cfg.providers
      );
    };
  };
}
