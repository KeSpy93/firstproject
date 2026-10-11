#!/usr/bin/env bash
# weiter.sh – prüft, was auf dem Mac schon eingerichtet ist, repariert typische
# Schäden (z. B. nach einem macOS-Update oder einem abgebrochenen Lauf) und
# installiert nur das, was noch fehlt. Kann beliebig oft ausgeführt werden.
#
# Aufruf (im Terminal, eine Zeile):
#   curl -fsSL https://raw.githubusercontent.com/KeSpy93/firstproject/claude/macbook-setup-tools-access-h0042c/mac-setup/weiter.sh -o ~/weiter.sh && bash ~/weiter.sh

set -u

RAW="https://raw.githubusercontent.com/KeSpy93/firstproject/claude/macbook-setup-tools-access-h0042c/mac-setup"
KIT="$HOME/mac-setup"
LOG="$HOME/Desktop/mac-setup-protokoll.txt"
[ -d "$HOME/Desktop" ] || LOG="$HOME/mac-setup-protokoll.txt"

STEP=0
TOTAL=8
FEHLER=""

schritt() { STEP=$((STEP + 1)); printf '\n\033[1;34m━━━ Schritt %s von %s: %s ━━━\033[0m\n' "$STEP" "$TOTAL" "$1"; }
ok()      { printf '   ✅ %s\n' "$1"; }
neu()     { printf '   🔧 %s\n' "$1"; }
warn()    { printf '   ⚠️  %s\n' "$1"; }
fehler()  { printf '   ❌ %s\n' "$1"; FEHLER="$FEHLER\n   • $1"; }

if [ "$(uname)" != "Darwin" ]; then
  echo "Dieses Skript ist nur für einen Mac gedacht." >&2
  exit 1
fi

# Alles zusätzlich in eine Datei auf dem Schreibtisch schreiben (zum Verschicken bei Problemen).
: > "$LOG"
exec > >(tee -a "$LOG") 2>&1

cat <<'EOF'

  ╔══════════════════════════════════════════════════════════════╗
  ║  Mac-Einrichtung: prüfen, reparieren, weitermachen           ║
  ╚══════════════════════════════════════════════════════════════╝

  • Das kann 30 bis 90 Minuten dauern. Bitte das Netzteil anschließen.
  • Der Mac geht währenddessen nicht in den Ruhezustand.
  • Bitte NICHTS eintippen, außer das Skript fragt dich ausdrücklich.
  • Ein Protokoll landet auf deinem Schreibtisch: mac-setup-protokoll.txt

EOF

# Mac wach halten, solange dieses Skript läuft.
caffeinate -dimsu -w $$ &

# ---------------------------------------------------------------------------
schritt "Passwort"
echo "   Gleich wirst du nach deinem Mac-Passwort gefragt (das, mit dem du dich am Mac anmeldest)."
echo "   Beim Tippen siehst du KEINE Zeichen und keine Sternchen – das ist normal."
echo "   Einfach blind tippen und Enter drücken."
echo
if ! sudo -v; then
  fehler "Das Passwort wurde nicht angenommen. Bitte das Skript neu starten und es noch einmal versuchen."
  exit 1
fi
# Passwort für die Laufzeit des Skripts gültig halten, damit nicht ständig gefragt wird.
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
ok "Passwort angenommen."

# ---------------------------------------------------------------------------
schritt "Apple-Entwicklerwerkzeuge (werden bei macOS-Updates oft beschädigt)"
clt_ok() { xcode-select -p >/dev/null 2>&1 && xcrun --find git >/dev/null 2>&1 && git --version >/dev/null 2>&1; }

if clt_ok; then
  ok "Entwicklerwerkzeuge funktionieren."
else
  neu "Entwicklerwerkzeuge fehlen oder sind kaputt – werden neu installiert (ca. 5–20 Minuten)."
  sudo xcode-select --reset >/dev/null 2>&1
  if ! clt_ok; then
    # Gleiches Verfahren wie der offizielle Homebrew-Installer: ohne Dialogfenster installieren.
    PLACEHOLDER=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    sudo touch "$PLACEHOLDER"
    LABEL=$(softwareupdate -l 2>/dev/null | grep -B 1 -E 'Command Line Tools' \
      | awk -F'*' '/^ *\*/ {print $2}' | sed -e 's/^ *Label: //' -e 's/^ *//' | sort -V | tail -n1)
    if [ -n "$LABEL" ]; then
      echo "   Installiere: $LABEL"
      sudo softwareupdate -i "$LABEL" --verbose
    fi
    sudo rm -f "$PLACEHOLDER"
    sudo xcode-select --switch /Library/Developer/CommandLineTools >/dev/null 2>&1
  fi
  if clt_ok; then
    ok "Entwicklerwerkzeuge repariert."
  else
    xcode-select --install >/dev/null 2>&1
    cat <<'EOF'

   ➜ Es öffnet sich gleich ein Fenster „Befehlszeilenentwickler-Tools“.
     1. Dort auf „Installieren“ klicken, dann „Akzeptieren“.
     2. Warten, bis „Die Software wurde installiert“ erscheint (5–20 Minuten).
     3. Danach hier im Terminal diese Zeile eintippen und Enter drücken:

            bash ~/weiter.sh

EOF
    exit 0
  fi
fi

# ---------------------------------------------------------------------------
schritt "Homebrew (das Programm, das alle anderen Programme installiert)"
if pgrep -f 'Library/Homebrew/brew.rb' >/dev/null 2>&1; then
  fehler "Es läuft noch eine alte Installation im Hintergrund. Bitte den Mac neu starten und das Skript erneut ausführen."
  exit 1
fi

if [ -x /opt/homebrew/bin/brew ]; then
  BREW=/opt/homebrew/bin/brew
elif [ -x /usr/local/bin/brew ]; then
  BREW=/usr/local/bin/brew
else
  neu "Homebrew fehlt – wird installiert."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x /opt/homebrew/bin/brew ]; then BREW=/opt/homebrew/bin/brew; else BREW=/usr/local/bin/brew; fi
fi
if [ ! -x "$BREW" ]; then
  fehler "Homebrew konnte nicht installiert werden. Bitte die Datei mac-setup-protokoll.txt an Claude schicken."
  exit 1
fi
eval "$("$BREW" shellenv)"
ok "Homebrew ist da ($(brew --version | head -n1))."

neu "Homebrew wird aktualisiert und überprüft …"
brew update >/dev/null 2>&1 || warn "Homebrew-Update hat nicht geklappt – wir machen trotzdem weiter."

# ~/.zprofile aufräumen: genau eine Homebrew-Zeile und ~/.local/bin (für Claude Code) im PATH.
ZP="$HOME/.zprofile"
touch "$ZP"
ANZAHL=$(grep -c 'brew shellenv' "$ZP" 2>/dev/null || true)
if [ "${ANZAHL:-0}" != "1" ]; then
  cp "$ZP" "$ZP.sicherung-$(date +%Y%m%d-%H%M%S)"
  grep -v 'brew shellenv' "$ZP" > "$ZP.tmp" || true
  echo "eval \"\$($BREW shellenv)\"" >> "$ZP.tmp"
  mv "$ZP.tmp" "$ZP"
  neu "Homebrew-Eintrag in ~/.zprofile repariert (Sicherung angelegt)."
else
  ok "~/.zprofile ist in Ordnung."
fi
if ! grep -q '.local/bin' "$ZP"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZP"
fi
export PATH="$HOME/.local/bin:$PATH"

# ---------------------------------------------------------------------------
schritt "Bauplan herunterladen (Liste der Programme und Einstellungen)"
mkdir -p "$KIT/claude"
LADEN_OK=1
for f in Brewfile mcp-setup.sh secrets.env.example claude/settings.json claude/CLAUDE.md; do
  if ! curl -fsSL "$RAW/$f" -o "$KIT/$f.neu"; then
    LADEN_OK=0
  else
    mv "$KIT/$f.neu" "$KIT/$f"
  fi
done
chmod +x "$KIT/mcp-setup.sh" 2>/dev/null
if [ "$LADEN_OK" = 1 ]; then
  ok "Bauplan liegt in ~/mac-setup."
elif [ -f "$KIT/Brewfile" ]; then
  warn "Download fehlgeschlagen – nehme die Version, die schon auf dem Mac liegt."
else
  fehler "Bauplan konnte nicht geladen werden. Ist das Internet verbunden?"
  exit 1
fi
BF="$KIT/Brewfile"

# ---------------------------------------------------------------------------
schritt "Programme prüfen und Fehlendes installieren (dauert am längsten)"
CELLAR="$(brew --cellar)"

# Ein Kommandozeilen-Tool gilt nur als fertig, wenn Homebrew die Installation abgeschlossen hat.
formel_fertig() { ls "$CELLAR/$1"/*/INSTALL_RECEIPT.json >/dev/null 2>&1; }

LISTE=$(grep -E '^(brew|cask) "' "$BF" | sed -E 's/^(brew|cask) "([^"]+)".*/\1 \2/')
GESAMT=$(printf '%s\n' "$LISTE" | grep -c .)
NR=0

while read -r ART NAME <&3; do
  [ -z "$NAME" ] && continue
  NR=$((NR + 1))
  PREFIX=$(printf '[%2s/%s] %-22s' "$NR" "$GESAMT" "$NAME")
  if [ "$ART" = "brew" ]; then
    if formel_fertig "$NAME"; then
      printf '   %s ✅ schon da\n' "$PREFIX"; continue
    fi
    printf '   %s 🔧 wird installiert …\n' "$PREFIX"
    if brew list --formula "$NAME" >/dev/null 2>&1; then
      brew reinstall "$NAME" || brew reinstall "$NAME" || fehler "$NAME (Kommandozeilen-Tool)"
    else
      brew install "$NAME" || brew install "$NAME" || fehler "$NAME (Kommandozeilen-Tool)"
    fi
  else
    if brew list --cask "$NAME" >/dev/null 2>&1; then
      printf '   %s ✅ schon da\n' "$PREFIX"; continue
    fi
    printf '   %s 🔧 wird installiert …\n' "$PREFIX"
    # Zweiter Versuch mit --force: überschreibt halb installierte Reste vom abgebrochenen Lauf.
    brew install --cask "$NAME" || brew install --cask --force "$NAME" || fehler "$NAME (Programm)"
  fi
done 3<<EOF
$LISTE
EOF

# Gegenprobe: Ist das Programm wirklich im Programme-Ordner? Sonst einmal neu installieren.
neu "Gegenprobe im Programme-Ordner …"
APPS="visual-studio-code|Visual Studio Code
jetbrains-toolbox|JetBrains Toolbox
iterm2|iTerm
epic-games|Epic Games Launcher
unity-hub|Unity Hub
godot|Godot
blender|Blender
freecad|FreeCAD
figma|Figma
inkscape|Inkscape
krita|krita
docker-desktop|Docker
android-studio|Android Studio
github|GitHub Desktop
postman|Postman
google-chrome|Google Chrome
firefox|Firefox
claude|Claude"
while IFS='|' read -r CASK APP <&3; do
  grep -q "^cask \"$CASK\"" "$BF" || continue
  [ -d "/Applications/$APP.app" ] && continue
  neu "$APP fehlt im Programme-Ordner – wird neu installiert."
  brew reinstall --cask --force "$CASK" || fehler "$APP"
done 3<<EOF
$APPS
EOF
ok "Programme fertig geprüft."

git lfs install >/dev/null 2>&1 && ok "Git LFS eingerichtet."

# ---------------------------------------------------------------------------
schritt "Claude Code (die Kommandozeilen-Version von Claude)"
if command -v claude >/dev/null 2>&1; then
  ok "Claude Code ist da ($(claude --version 2>/dev/null | head -n1))."
else
  neu "Claude Code wird installiert."
  curl -fsSL https://claude.ai/install.sh | bash
  hash -r
  if command -v claude >/dev/null 2>&1; then ok "Claude Code installiert."; else fehler "Claude Code"; fi
fi

# ---------------------------------------------------------------------------
schritt "Einstellungen für Claude und Projektordner"
mkdir -p "$HOME/.claude"
if [ -f "$HOME/.claude/settings.json" ]; then
  ok "~/.claude/settings.json gibt es schon – bleibt unverändert."
else
  cp "$KIT/claude/settings.json" "$HOME/.claude/settings.json" && neu "~/.claude/settings.json angelegt."
fi
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  ok "~/.claude/CLAUDE.md gibt es schon – bleibt unverändert."
else
  cp "$KIT/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md" && neu "~/.claude/CLAUDE.md angelegt."
fi
mkdir -p "$HOME/Projects/apps" "$HOME/Projects/games" "$HOME/Projects/cad" \
         "$HOME/Projects/tools" "$HOME/Projects/simulation" "$HOME/Projects/design"
ok "Projektordner unter ~/Projects sind da."

# ---------------------------------------------------------------------------
schritt "Ergebnis"
for CMD in brew git node python3 uv gh claude; do
  if command -v "$CMD" >/dev/null 2>&1; then ok "$CMD"; else fehler "Befehl $CMD fehlt"; fi
done

echo
if [ -d /Applications/Xcode.app ]; then
  ok "Xcode ist installiert."
else
  warn "Xcode fehlt noch (nur für iPhone-/Mac-Apps nötig). Das machst du von Hand:"
  echo "      App Store öffnen → oben links „Xcode“ suchen → „Laden“ klicken. (ca. 15 GB)"
fi
warn "Unreal Engine installierst du von Hand: Epic Games Launcher öffnen → links „Unreal Engine“ → oben „Bibliothek“ → gelbes „+“."

echo
if [ -z "$FEHLER" ]; then
  printf '\033[1;32m   🎉 Alles erledigt! Es ist nichts mehr offen.\033[0m\n'
else
  printf '\033[1;33m   Fast fertig. Das hat nicht geklappt:\033[0m'
  printf "$FEHLER\n"
  echo
  echo "   ➜ Einfach das Skript noch einmal starten:   bash ~/weiter.sh"
  echo "     Wenn es dann immer noch nicht klappt: die Datei mac-setup-protokoll.txt"
  echo "     vom Schreibtisch an Claude schicken."
fi

cat <<'EOF'

   Nächster Schritt: Terminal komplett schließen (Cmd + Q), neu öffnen und eintippen:

        claude

   Dann der Anleitung im Chat folgen.

EOF
sleep 1
