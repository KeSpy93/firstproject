#!/usr/bin/env bash
# Richtet MCP-Server für Claude Code ein (Scope "user" = in allen Projekten verfügbar).
#
# Aufruf:   bash mac-setup/mcp-setup.sh
# Tokens werden aus ~/.claude/secrets.env gelesen (Vorlage: secrets.env.example).
# Server, deren Token fehlt, werden übersprungen. Mehrfach ausführbar.
set -uo pipefail

SECRETS="$HOME/.claude/secrets.env"
# shellcheck disable=SC1090
[ -f "$SECRETS" ] && . "$SECRETS"

PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Projects}"

# Ohne eigenen Token den von 'gh auth login' verwenden.
if [ -z "${GITHUB_PAT:-}" ] && command -v gh >/dev/null 2>&1; then
  GITHUB_PAT="$(gh auth token 2>/dev/null || true)"
fi

command -v claude >/dev/null 2>&1 || { echo "Claude Code fehlt – zuerst setup.sh ausführen." >&2; exit 1; }
command -v npx    >/dev/null 2>&1 || { echo "Node.js fehlt – zuerst setup.sh ausführen." >&2; exit 1; }
command -v uvx    >/dev/null 2>&1 || { echo "uv fehlt – zuerst setup.sh ausführen." >&2; exit 1; }

# Entfernt einen vorhandenen Eintrag und legt ihn neu an.
add() {
  local name="$1"; shift
  claude mcp remove --scope user "$name" >/dev/null 2>&1 || true
  if claude mcp add --scope user "$name" "$@"; then
    printf '  ✔ %s\n' "$name"
  else
    printf '  ✘ %s (fehlgeschlagen)\n' "$name"
  fi
}

skip() { printf '  – %s übersprungen (%s fehlt in %s)\n' "$1" "$2" "$SECRETS"; }

echo "== Basis =="
add filesystem          -- npx -y @modelcontextprotocol/server-filesystem "$PROJECTS_DIR" "$HOME/Documents" "$HOME/Desktop" "$HOME/Downloads"
add memory              -- npx -y @modelcontextprotocol/server-memory
add sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
add context7            -- npx -y @upstash/context7-mcp          # aktuelle Doku zu Bibliotheken/Frameworks
add playwright          -- npx -y @playwright/mcp@latest         # Browser steuern, Web-Apps testen

echo "== Entwicklung =="
if [ -n "${GITHUB_PAT:-}" ]; then
  add github --transport http https://api.githubcopilot.com/mcp/ --header "Authorization: Bearer $GITHUB_PAT"
else
  skip github "GitHub-Anmeldung (gh auth login)"
fi
add xcodebuild -- npx -y xcodebuildmcp@latest                    # iOS/macOS-Apps bauen & im Simulator testen

echo "== 3D / Design =="
add blender --env BLENDER_HOST=localhost -- uvx blender-mcp      # benötigt das Blender-Add-on (siehe README)
add figma --transport http http://127.0.0.1:3845/mcp             # Figma Desktop → Dev Mode MCP Server aktivieren

echo "== Online-Dienste (Anmeldung per OAuth beim ersten Aufruf mit /mcp) =="
add notion  --transport http https://mcp.notion.com/mcp
add linear  --transport http https://mcp.linear.app/mcp
add sentry  --transport http https://mcp.sentry.dev/mcp

echo
echo "Status:"
claude mcp list
cat <<'EOF'

Hinweise:
  • OAuth-Dienste (Notion, Linear, Sentry): in Claude Code '/mcp' eingeben und anmelden.
  • Gmail, Google Drive, Canva usw.: auf claude.ai unter Einstellungen → Connectors verbinden.
    Diese stehen automatisch auch in Claude Code zur Verfügung, wenn du mit demselben Konto angemeldet bist.
  • Unreal Engine, Unity, FreeCAD: siehe README, Abschnitt "MCP für Engines & CAD".
EOF
