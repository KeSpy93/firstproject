#!/usr/bin/env bash
# Grundinstallation für macOS: Homebrew, alle Tools aus dem Brewfile, Claude Code
# und die globale Claude-Code-Konfiguration.
#
# Aufruf (im Repo-Ordner):   bash mac-setup/setup.sh
# Mehrfach ausführbar – bereits Installiertes wird übersprungen.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

say() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }

if [ "$(uname)" != "Darwin" ]; then
  echo "Dieses Skript ist für macOS gedacht." >&2
  exit 1
fi

say "Xcode Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install || true
  echo "Bitte die Installation im Dialog abschließen und das Skript danach erneut starten."
  exit 0
fi

say "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if [ -x /opt/homebrew/bin/brew ]; then
  BREW=/opt/homebrew/bin/brew      # Apple Silicon
else
  BREW=/usr/local/bin/brew         # Intel
fi
eval "$("$BREW" shellenv)"
if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
  echo "eval \"\$($BREW shellenv)\"" >> "$HOME/.zprofile"
fi

say "Mac App Store Anmeldung prüfen (für Xcode)"
echo "Falls Xcode fehlschlägt: im App Store anmelden und 'brew bundle' erneut ausführen."

say "Programme aus dem Brewfile installieren (kann lange dauern)"
brew bundle --file="$SCRIPT_DIR/Brewfile" || echo "Einige Pakete sind fehlgeschlagen – siehe Ausgabe oben."

say "Git LFS"
git lfs install

say "Claude Code (CLI)"
if ! command -v claude >/dev/null 2>&1; then
  curl -fsSL https://claude.ai/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
fi
claude --version || true

say "Globale Claude-Code-Konfiguration"
mkdir -p "$HOME/.claude"
if [ ! -f "$HOME/.claude/settings.json" ]; then
  cp "$SCRIPT_DIR/claude/settings.json" "$HOME/.claude/settings.json"
  echo "~/.claude/settings.json angelegt."
else
  echo "~/.claude/settings.json existiert bereits – Vorlage liegt in mac-setup/claude/settings.json."
fi
if [ ! -f "$HOME/.claude/CLAUDE.md" ]; then
  cp "$SCRIPT_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  echo "~/.claude/CLAUDE.md angelegt."
fi

say "Projektordner"
mkdir -p "$HOME/Projects"/{apps,games,cad,tools,simulation,design}

say "Fertig"
cat <<'EOF'
Nächste Schritte:
  1. Terminal neu öffnen und 'claude' starten → mit deinem Claude-Konto anmelden.
  2. 'gh auth login' ausführen (GitHub).
  3. API-Tokens eintragen:   cp mac-setup/secrets.env.example ~/.claude/secrets.env  (dann bearbeiten)
  4. MCP-Server einrichten:  bash mac-setup/mcp-setup.sh
  5. macOS-Berechtigungen setzen (siehe README, Abschnitt "macOS-Berechtigungen").
  6. Unreal Engine über den Epic Games Launcher installieren.
EOF
