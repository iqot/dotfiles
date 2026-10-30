{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (config.dotfiles) flakeOptions;
  isGenericLinux = config.targets.genericLinux.enable or false;
  isNixOS = isLinux && !isGenericLinux;
  cfg = config.dotfiles.profiles;

  # Node is deliberately kept off the interactive PATH. Only the AI agents get
  # it, which is enough for everything they spawn themselves: npx-based MCP
  # servers, skill helper scripts, and the like.
  withNode =
    programs: package:
    pkgs.symlinkJoin {
      name = "${package.name}-with-node";
      paths = [ package ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = lib.concatMapStringsSep "\n" (program: ''
        wrapProgram $out/bin/${program} \
          --prefix PATH : ${lib.makeBinPath [ pkgs.nodejs_22 ]}
      '') programs;
    };

  # nixpkgs gained herdr just after this flake.lock pin, and herdr's own flake
  # builds it from source (Rust + Zig) with no cache behind it. herdr-nix wraps
  # the upstream release binaries, keeping this a hash-verified download.
  herdr = inputs.herdr-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Agents only discover skills one level deep, so each upstream category
  # becomes its own source with maxDepth 1. Recursing instead would yield
  # nested IDs like "engineering/tdd", which land at a path no agent reads.
  mattpocockSkills = category: {
    path = inputs.mattpocock-skills;
    subdir = "skills/${category}";
    filter.maxDepth = 1;
  };
in
{
  options.dotfiles.profiles.development.enable = lib.mkEnableOption "development packages";

  config = lib.mkIf cfg.development.enable {
    home.packages =
      with pkgs;
      [
        devenv
        git-absorb
        github-cli
        ast-grep
        shellcheck
        tokei
        universal-ctags
        (withNode [ "claude" ] claude-code)
        antigravity-cli
        herdr
        prettier
      ]
      # semgrep-core crashes patchelf on Linux in current nixpkgs-unstable.
      # Restore it there once https://github.com/NixOS/nixpkgs/issues/579107 is fixed.
      ++ lib.optionals (!isLinux) [ semgrep ]
      ++ lib.optionals isLinux [ distrobox ]
      ++ lib.optionals isNixOS [ man-pages ]
      ++ lib.optionals cfg.extras.enable [ nixos-shell ];

    programs.agent-skills = {
      enable = true;

      sources = {
        vercel = {
          path = inputs.vercel-skills;
          subdir = "skills";
          filter.maxDepth = 1;
        };
        engineering = mattpocockSkills "engineering";
        productivity = mattpocockSkills "productivity";
        misc = mattpocockSkills "misc";
      };

      skills.enableAll = [
        "vercel"
        "engineering"
        "productivity"
        "misc"
      ];

      # "link" keeps the skills as home.file symlinks. The default
      # "symlink-tree" would rsync --delete the destination on every
      # activation, taking any plugin or claude.ai-synced skill with it.
      #
      # dest is a literal path rather than the upstream default of
      # "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills". A dest holding shell
      # variables is only resolved at activation time, where session variables
      # are not exported, so it cannot be trusted to expand to the right
      # directory. CLAUDE_CONFIG_DIR is unset here anyway and ~/.claude is the
      # real config dir.
      targets.claude = {
        enable = true;
        structure = "link";
        dest = ".claude/skills";
      };
    };

    programs.direnv = {
      enable = lib.mkDefault true;
      nix-direnv.enable = lib.mkDefault true;
    };

    programs.jujutsu = {
      enable = lib.mkDefault true;
      settings = {
        user = {
          name = flakeOptions.user.fullName;
          email = flakeOptions.user.email;
        };
      };
    };

    dotfiles.gitsign = {
      enable = lib.mkDefault true;
      enableCredentialCache = lib.mkDefault true;
      settings.connectorID = lib.mkDefault "https://github.com/login/oauth";
    };
  };
}
