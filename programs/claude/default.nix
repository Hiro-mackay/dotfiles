# Claude Code: package, settings, CLAUDE.md, skills, plugins and MCP all come from Nix.
# settings.json is read-only, so /model, /config and /plugin changes last only for the
# session; edit settings.json here and switch to keep them. The deny rules guard
# against accidents, not against a determined agent: the file is a symlink in the
# user's home that a plain rm can replace.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  skills = ../agents/skills;
  guardrails = import ../agents/guardrails.nix;
  settings = builtins.fromJSON (builtins.readFile ./settings.json);
  claude = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;

  # Copies conversations and memory into the vault's .depth/, then syncs the vault and
  # runs the daily agents in a detached run (see vault-capture.py). git and claude come
  # from Nix so the hook does not depend on the PATH of whatever started Claude Code.
  capture = pkgs.writeShellScript "vault-capture" ''
    export VAULT_RCLONE=${pkgs.rclone}/bin/rclone VAULT_CLAUDE=${claude}/bin/claude
    export PATH="${pkgs.git}/bin:$PATH"
    exec ${pkgs.python3}/bin/python3 ${./vault-capture.py} "$@"
  '';
  hook = arg: [
    {
      hooks = [
        {
          type = "command";
          command = "${capture} ${arg}";
          # SessionEnd hooks share a 1.5 s budget unless an entry sets a longer timeout.
          timeout = 30;
        }
      ];
    }
  ];
in
{
  # The same rclone the capture hook runs, so `rclone config` sets up its remote.
  home.packages = lib.optional config.dotfiles.vault.enable pkgs.rclone;

  # i-have-adhd's SessionStart hook injects its rules only while this file exists.
  home.file."${config.programs.claude-code.configDir}/.i-have-adhd-always".text = "";

  # pstack's per-role model overrides, loaded by the @ line at the end of CLAUDE.md.
  home.file."${config.programs.claude-code.configDir}/pstack-models.md".source = ./pstack-models.md;

  programs.claude-code = {
    enable = true;
    # A machine that installs Claude Code some other way sets this to null.
    package = lib.mkDefault claude;

    # Shared rules (agents/AGENTS.md) plus the Claude-only section.
    context = builtins.readFile ../agents/AGENTS.md + "\n" + builtins.readFile ./CLAUDE.md;

    # One directory link per skill (an attrset, not a path) so tool-owned entries such
    # as skills/synced keep living next to them. critique is for Codex only.
    skills = lib.mapAttrs (name: _: skills + "/${name}") (
      removeAttrs (builtins.readDir skills) [ "critique" ]
    );

    # Marketplace plugins pinned through flake inputs, loaded as personal plugins.
    plugins = {
      # home-manager's mkPluginEntry symlinks each top-level source entry into the
      # plugin store path individually, so hooks/ stays a symlink to the flake
      # input's own store path. ponytail's manifest points "hooks" at an explicit
      # file (./hooks/claude-codex-hooks.json); Claude Code resolves that through
      # the symlink and rejects it as outside the plugin directory. codex and warp
      # don't hit this because they rely on the default hooks/hooks.json location
      # instead of naming a path. Copy the source and rename the hooks file to the
      # default so ponytail resolves the same way.
      ponytail = pkgs.runCommand "ponytail-plugin" { nativeBuildInputs = [ pkgs.jq ]; } ''
        cp -r ${inputs.ponytail} $out
        chmod -R u+w $out
        mv $out/hooks/claude-codex-hooks.json $out/hooks/hooks.json
        jq 'del(.hooks)' ${inputs.ponytail}/.claude-plugin/plugin.json > $out/.claude-plugin/plugin.json
      '';
      codex = "${inputs.codex-plugin-cc}/plugins/codex";
      # pstack tells the agent to open PRs, file issues and message others without asking,
      # against AGENTS.md. --replace-fail stops the build when upstream rewords a line,
      # so an update cannot bring the old wording back unnoticed.
      pstack = pkgs.runCommand "pstack-plugin" { } ''
        cp -r ${inputs.pstack-claude}/plugins/pstack $out
        chmod -R u+w $out
        substituteInPlace $out/skills/poteto-mode/SKILL.md \
          --replace-fail \
            "**Just do it.** Use any MCP tool. Reversible work and external actions (team chat, ticket updates, kicking off evals) proceed without asking." \
            "**Ask before anything leaves this machine.** Commits, pushes, pull requests, issues, tracker or chat messages and deploys wait for the user's request in this session, whatever a playbook or skill in this plugin says. Reversible local work proceeds without asking. A session override below covers local work only." \
          --replace-fail \
            "Broken skill mid-task → fix it in its own PR. Don't block. Don't silently work around it." \
            "Broken skill mid-task → report it to the user. Don't silently work around it."
        substituteInPlace $out/skills/poteto-mode/playbooks/opening-a-pr.md \
          --replace-fail \
            "Invoked at the end of every other playbook." \
            "Invoked only when the user asked for a pull request in this session."
        substituteInPlace $out/skills/reflect/SKILL.md \
          --replace-fail \
            "File each Backlog item to your team's devex or backlog tracker without waiting. Only the Accepted list waits for approval." \
            "List each Backlog item for the user. File one to a tracker only when they ask."
      '';
      # Notifications go through Warp (OSC 777, also over SSH); preferredNotifChannel is off.
      warp = "${inputs.claude-code-warp}/plugins/warp";
      # caveman and i-have-adhd hooks run node from PATH; point them at Nix's node
      # instead, as the capture hook does. caveman already stays off in print-mode
      # runs (CLAUDE_CODE_ENTRYPOINT=sdk-*), such as the vault's daily agents;
      # i-have-adhd is made to skip them too so it does not shape their notes.
      caveman = pkgs.runCommand "caveman-plugin" { } ''
        cp -r ${inputs.caveman} $out
        chmod -R u+w $out
        sed -i -e 's#command -v node >/dev/null 2>&1 || exit 0; ##' \
          -e 's#; node \\"\$HOOK_ROOT#; ${pkgs.nodejs}/bin/node \\"$HOOK_ROOT#' \
          $out/.claude-plugin/plugin.json
        test "$(grep -c '${pkgs.nodejs}/bin/node' $out/.claude-plugin/plugin.json)" = 4
        ! grep -q 'command -v node' $out/.claude-plugin/plugin.json
        # Plugin skills can't be turned off one by one (skillOverrides skips them), so
        # drop what isn't wanted: the Caveman Cloud skills need the proxy CLI, and the
        # rest would run on Haiku or rewrite reviews, commits and CLAUDE.md on their own.
        rm -r $out/skills/{cavecrew,caveman-explore,caveman-review,caveman-commit,caveman-compress,caveman-setup,caveman-discover,caveman-manage,caveman-optimize,caveman-evidence-review,caveman-learn} \
          $out/agents/cavecrew-*.md
        # caveman-init pipes a script from the upstream main branch into node, past the pin.
        rm $out/commands/caveman-init.*
      '';
      i-have-adhd = pkgs.runCommand "i-have-adhd-plugin" { nativeBuildInputs = [ pkgs.jq ]; } ''
        cp -r ${inputs.i-have-adhd} $out
        chmod -R u+w $out
        jq --arg cmd 'case "$CLAUDE_CODE_ENTRYPOINT" in sdk-*) exit 0 ;; esac; exec ${pkgs.nodejs}/bin/node '"$out"'/hooks/always-on.mjs' \
          '.hooks.SessionStart[0].hooks[0].command = $cmd' \
          ${inputs.i-have-adhd}/hooks/hooks.json > $out/hooks/hooks.json
      '';
    };

    # By store path, as in programs/codex: apps started by launchd lack the profile's PATH.
    mcpServers.codebase-memory-mcp.command = "${pkgs.codebase-memory-mcp}/bin/codebase-memory-mcp";

    settings = settings // {
      permissions = settings.permissions // {
        deny =
          settings.permissions.deny
          ++ map (cmd: "Bash(${lib.concatStringsSep " " cmd}:*)") guardrails.commands
          ++ lib.concatMap (path: [
            "Read(~/${path})"
            "Read(~/${path}/**)"
          ]) guardrails.secrets;
      };
      statusLine = {
        type = "command";
        command = "${./statusline.sh}";
      };
      hooks = lib.mkIf config.dotfiles.vault.enable {
        SessionEnd = hook "end";
        SessionStart = hook "start";
      };
    };
  };
}
