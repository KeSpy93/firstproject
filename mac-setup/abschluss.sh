#!/usr/bin/env bash
# abschluss.sh – Speicher freimachen und Einrichtung abschließen:
#   1. Autodesk Fusion komplett entfernen (Programme, Einstellungen, Lizenzdienste, Schlüsselbund)
#   2. selten gebrauchte Entwickler-Programme deinstallieren (bei Bedarf später wieder installierbar)
#   3. doppelte Programme finden; echte Doppel (gleiches Programm) in den Papierkorb
#   4. Homebrew-Download-Reste löschen
#   5. GitHub anmelden und MCP-Server für Claude einrichten
# Gelöscht wird nur, was zu den genannten Programmen gehört. Mehrfach ausführbar.
#
#   curl -fsSL https://raw.githubusercontent.com/KeSpy93/firstproject/claude/macbook-setup-tools-access-h0042c/mac-setup/abschluss.sh -o ~/abschluss.sh && bash ~/abschluss.sh

set -u
shopt -s nullglob

RAW="https://raw.githubusercontent.com/KeSpy93/firstproject/claude/macbook-setup-tools-access-h0042c/mac-setup"
KIT="$HOME/mac-setup"
LOG="$HOME/Desktop/mac-setup-abschluss-protokoll.txt"
[ -d "$HOME/Desktop" ] || LOG="$HOME/mac-setup-abschluss-protokoll.txt"

# Programme, die vorerst nicht gebraucht werden: Homebrew-Name|Anzeigename|mit Programmdaten löschen (zap)
CASKS_WEG="android-studio|Android Studio|ja
flutter|Flutter|ja
dotnet-sdk|.NET SDK|ja
unity-hub|Unity Hub|ja
docker-desktop|Docker|ja
jetbrains-toolbox|JetBrains Toolbox|ja
paraview|ParaView|ja
inkscape|Inkscape|ja
krita|Krita|ja
postman|Postman|ja
iterm2|iTerm|ja
github|GitHub Desktop|ja
firefox|Firefox|nein"
FORMELN_WEG="go rust"

STEP=0
TOTAL=7
FEHLER=""
TILDE='~'
schritt() { STEP=$((STEP + 1)); printf '\n\033[1;34m━━━ Schritt %s von %s: %s ━━━\033[0m\n' "$STEP" "$TOTAL" "$1"; }
ok()      { printf '   ✅ %s\n' "$1"; }
neu()     { printf '   🔧 %s\n' "$1"; }
warn()    { printf '   ⚠️  %s\n' "$1"; }
fehler()  { printf '   ❌ %s\n' "$1"; FEHLER="$FEHLER\n   • $1"; }
frei()    { df -H / | awk 'NR==2 {print $4}'; }

[ "$(uname)" = "Darwin" ] || { echo "Nur für den Mac gedacht." >&2; exit 1; }

# Terminal merken (für Anmeldungen, die ein echtes Terminal brauchen), dann alles mitprotokollieren.
exec 5>&1 6>&2
: > "$LOG"
exec > >(tee -a "$LOG") 2>&1

if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)";
elif [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)";
else echo "Homebrew fehlt – bitte zuerst weiter.sh ausführen."; exit 1; fi
export PATH="$HOME/.local/bin:$PATH"

FREI_VORHER=$(frei)

cat <<EOF

  ╔══════════════════════════════════════════════════════════════╗
  ║  Aufräumen und Einrichtung abschließen                       ║
  ╚══════════════════════════════════════════════════════════════╝

  Freier Speicher gerade: $FREI_VORHER

  Dieses Skript wird:
   • Autodesk Fusion KOMPLETT entfernen (inkl. Einstellungen, Lizenzdaten, Anmeldedaten)
   • diese Programme deinstallieren (Claude installiert sie wieder, wenn ein Projekt sie braucht):
       Android Studio, Flutter, .NET SDK, Unity Hub, Docker, JetBrains Toolbox, ParaView,
       Inkscape, Krita, Postman, iTerm, GitHub Desktop, Firefox, Go, Rust
   • doppelte Programme suchen
   • danach GitHub anmelden und Claude mit deinen Programmen verbinden

  Deine eigenen Dateien (Dokumente, Fotos, Projekte, Fusion-Exporte) werden NICHT angefasst.

EOF
printf '  ➜ Weiter mit der Enter-Taste. Abbrechen: Terminal-Fenster schließen. '
read -r _ </dev/tty

caffeinate -dimsu -w $$ &

# ---------------------------------------------------------------------------
schritt "Passwort"
echo "   Dein Mac-Passwort eingeben. Beim Tippen siehst du nichts – das ist normal. Dann Enter."
sudo -v || { fehler "Passwort nicht angenommen."; exit 1; }
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
ok "Passwort angenommen."

# Neueste Fassung von Bauplan und MCP-Einrichtung holen (damit weiter.sh nichts zurückholt).
mkdir -p "$KIT"
for f in Brewfile mcp-setup.sh; do
  curl -fsSL "$RAW/$f" -o "$KIT/$f.neu" && mv "$KIT/$f.neu" "$KIT/$f"
done
curl -fsSL "$RAW/weiter.sh" -o "$HOME/weiter.sh.neu" && mv "$HOME/weiter.sh.neu" "$HOME/weiter.sh"

# ---------------------------------------------------------------------------
schritt "Autodesk Fusion komplett entfernen"

bundle_id() { /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$1/Contents/Info.plist" 2>/dev/null; }

# Gibt es außer Fusion noch andere Autodesk-Programme? Dann gemeinsame Autodesk-Ordner behalten.
ANDERE_AUTODESK=""
for app in /Applications/*.app /Applications/*/*.app "$HOME/Applications"/*.app "$HOME/Applications"/*/*.app; do
  bid=$(bundle_id "$app")
  case "$(echo "$bid" | tr 'A-Z' 'a-z')" in
    com.autodesk.*) case "$(echo "$app $bid" | tr 'A-Z' 'a-z')" in
                      *fusion*|*webdeploy*|*remove*|*identity*|*genuine*|*licens*|*access*) ;;
                      *) ANDERE_AUTODESK="$ANDERE_AUTODESK $(basename "$app")" ;;
                    esac ;;
  esac
done

weg() {  # weg <pfad> … – löscht vorhandene Pfade und meldet sie
  for p in "$@"; do
    [ -e "$p" ] || [ -L "$p" ] || continue
    if rm -rf "$p" 2>/dev/null || sudo rm -rf "$p" 2>/dev/null; then
      echo "      gelöscht: ${p/#$HOME/$TILDE}"
    elif osascript -e "tell application \"Finder\" to delete (POSIX file \"$p\" as alias)" >/dev/null 2>&1; then
      echo "      in den Papierkorb: ${p/#$HOME/$TILDE}"
    else
      fehler "Konnte nicht löschen: ${p/#$HOME/$TILDE} (Terminal braucht „App-Verwaltung“ und „Festplattenvollzugriff“)"
    fi
  done
}

echo "   Fusion-Prozesse beenden …"
osascript -e 'quit app "Autodesk Fusion"' >/dev/null 2>&1
osascript -e 'quit app "Autodesk Fusion 360"' >/dev/null 2>&1
sleep 2
sudo pkill -9 -if 'autodesk' >/dev/null 2>&1

echo "   Hintergrunddienste von Autodesk stoppen …"
for plist in "$HOME/Library/LaunchAgents"/com.autodesk.* "$HOME/Library/LaunchAgents"/*[Aa]utodesk* ; do
  launchctl bootout "gui/$(id -u)" "$plist" >/dev/null 2>&1
  weg "$plist"
done
for plist in /Library/LaunchAgents/com.autodesk.* /Library/LaunchAgents/*[Aa]utodesk* /Library/LaunchAgents/*[Aa]dsk*; do
  sudo launchctl bootout "gui/$(id -u)" "$plist" >/dev/null 2>&1
  weg "$plist"
done
for plist in /Library/LaunchDaemons/com.autodesk.* /Library/LaunchDaemons/*[Aa]utodesk* /Library/LaunchDaemons/*[Aa]dsk*; do
  sudo launchctl bootout system "$plist" >/dev/null 2>&1
  weg "$plist"
done

echo "   Programme löschen …"
for app in /Applications/*.app /Applications/*/*.app "$HOME/Applications"/*.app "$HOME/Applications"/*/*.app; do
  bid=$(bundle_id "$app" | tr 'A-Z' 'a-z')
  name=$(basename "$app" | tr 'A-Z' 'a-z')
  case "$bid" in
    com.autodesk.*)
      if [ -z "$ANDERE_AUTODESK" ] || echo "$name $bid" | grep -qE 'fusion|webdeploy'; then weg "$app"; fi ;;
  esac
done
for d in /Applications/Autodesk* "$HOME/Applications"/Autodesk*; do
  [ -d "$d" ] && [ -z "$(ls -A "$d" 2>/dev/null)" ] && weg "$d"   # leere Autodesk-Ordner
done

echo "   Einstellungen, Zwischenspeicher, Lizenzdaten löschen …"
L="$HOME/Library"
weg "$L/Application Support/Autodesk/webdeploy" \
    "$L"/Application\ Support/Autodesk*Fusion* \
    "$L"/Caches/com.autodesk.fusion* "$L"/Preferences/com.autodesk.fusion* \
    "$L"/Saved\ Application\ State/com.autodesk.fusion* \
    "$L"/HTTPStorages/com.autodesk.fusion* "$L"/WebKit/com.autodesk.fusion* \
    "$L"/Containers/com.autodesk.fusion* "$L"/Cookies/com.autodesk.fusion*
if [ -z "$ANDERE_AUTODESK" ]; then
  weg "$L/Application Support/Autodesk" "$L/Autodesk" \
      "$L"/Caches/com.autodesk.* "$L"/Caches/Autodesk* \
      "$L"/Preferences/com.autodesk.* "$L"/Preferences/Autodesk* \
      "$L"/Logs/Autodesk* "$L"/Logs/com.autodesk.* \
      "$L"/Saved\ Application\ State/com.autodesk.* \
      "$L"/HTTPStorages/com.autodesk.* "$L"/WebKit/com.autodesk.* \
      "$L"/Containers/com.autodesk.* "$L"/Group\ Containers/*autodesk* \
      "$L"/Cookies/com.autodesk.* \
      "/Library/Application Support/Autodesk" \
      /Library/Preferences/com.autodesk.* /Library/Logs/Autodesk* \
      /Library/PrivilegedHelperTools/com.autodesk.* /Library/PrivilegedHelperTools/*adsk* \
      /Users/Shared/Autodesk
  for pkg in $(pkgutil --pkgs 2>/dev/null | grep -i autodesk); do
    sudo pkgutil --forget "$pkg" >/dev/null 2>&1
  done
else
  warn "Andere Autodesk-Programme gefunden:$ANDERE_AUTODESK"
  warn "Deshalb nur Fusion-eigene Daten gelöscht, gemeinsame Autodesk-Lizenzdaten bleiben."
fi

echo "   Gespeicherte Autodesk-Anmeldungen im Schlüsselbund löschen …"
ANZ=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  SVC=$(security dump-keychain 2>/dev/null | grep -iE '"(svce|srvr)"<blob>=".*autodesk' | head -n1 \
        | sed -E 's/.*<blob>="(.*)"/\1/')
  [ -z "$SVC" ] && break
  security delete-generic-password -s "$SVC" >/dev/null 2>&1 \
    || security delete-internet-password -s "$SVC" >/dev/null 2>&1 \
    || break
  ANZ=$((ANZ + 1))
done
ok "Fusion entfernt ($ANZ Schlüsselbund-Einträge gelöscht)."

# ---------------------------------------------------------------------------
schritt "Selten gebrauchte Programme deinstallieren"
while IFS='|' read -r CASK NAME ZAP <&3; do
  [ -z "$CASK" ] && continue
  if brew list --cask "$CASK" >/dev/null 2>&1; then
    printf '   %-20s wird entfernt …\n' "$NAME"
    if [ "$ZAP" = "ja" ]; then
      brew uninstall --cask --zap --force "$CASK" >/dev/null 2>&1 || brew uninstall --cask --force "$CASK" >/dev/null 2>&1 \
        || fehler "$NAME konnte nicht entfernt werden"
    else
      brew uninstall --cask --force "$CASK" >/dev/null 2>&1 || fehler "$NAME konnte nicht entfernt werden"
    fi
  else
    printf '   %-20s ✅ schon weg\n' "$NAME"
  fi
done 3<<EOF
$CASKS_WEG
EOF
for F in $FORMELN_WEG; do
  if brew list --formula "$F" >/dev/null 2>&1; then
    printf '   %-20s wird entfernt …\n' "$F"
    brew uninstall --ignore-dependencies "$F" >/dev/null 2>&1 || fehler "$F konnte nicht entfernt werden"
  else
    printf '   %-20s ✅ schon weg\n' "$F"
  fi
done
# Docker hinterlässt eine große virtuelle Festplatte, falls zap sie nicht erwischt hat.
weg "$HOME/Library/Containers/com.docker.docker" "$HOME/Library/Group Containers/group.com.docker" "$HOME/.docker"
# Android-Studio-Downloads (SDK, Emulatoren)
weg "$HOME/Library/Android" "$HOME/.android" "$HOME/.gradle"
ok "Fertig."

# ---------------------------------------------------------------------------
schritt "Doppelte Programme suchen"
LISTE=""
for app in /Applications/*.app /Applications/*/*.app "$HOME/Applications"/*.app "$HOME/Applications"/*/*.app \
           "$HOME/Downloads"/*.app "$HOME/Downloads"/*/*.app "$HOME/Desktop"/*.app; do
  name=$(basename "$app" .app | sed -E 's/ [0-9]+$//')
  bid=$(bundle_id "$app")
  ver=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist" 2>/dev/null)
  LISTE="$LISTE$name|$app|$bid|$ver
"
done
DOPPELT=$(printf '%s' "$LISTE" | awk -F'|' 'NF>1 {n[tolower($1)]++} END {for (k in n) if (n[k]>1) print k}')
if [ -z "$DOPPELT" ]; then
  ok "Keine doppelten Programme gefunden."
else
  printf '%s\n' "$DOPPELT" | while read -r D; do
    echo "   Doppelt: $D"
    GRUPPE=$(printf '%s' "$LISTE" | awk -F'|' -v d="$D" 'tolower($1)==d')
    BEHALTEN=$(printf '%s\n' "$GRUPPE" | awk -F'|' '$2 ~ /^\/Applications\/[^\/]+\.app$/ && $2 !~ / [0-9]+\.app$/ {print $2; exit}')
    [ -z "$BEHALTEN" ] && BEHALTEN=$(printf '%s\n' "$GRUPPE" | head -n1 | cut -d'|' -f2)
    BID_BEHALTEN=$(printf '%s\n' "$GRUPPE" | awk -F'|' -v p="$BEHALTEN" '$2==p {print $3}')
    printf '%s\n' "$GRUPPE" | while IFS='|' read -r N P B V; do
      [ -z "$P" ] && continue
      ART="Programm"
      case "$B" in
        com.apple.Safari.WebApp*) ART="Web-App aus Safari (nur eine Verknüpfung zur Webseite)" ;;
        com.google.Chrome.app.*)  ART="Web-App aus Chrome (nur eine Verknüpfung zur Webseite)" ;;
        com.anthropic.claudefordesktop) ART="Claude Desktop-App" ;;
      esac
      if [ "$P" = "$BEHALTEN" ]; then
        echo "      ✅ behalten:  ${P/#$HOME/$TILDE}   ($ART, Version ${V:-?})"
      elif [ -n "$B" ] && [ "$B" = "$BID_BEHALTEN" ]; then
        if osascript -e "tell application \"Finder\" to delete (POSIX file \"$P\" as alias)" >/dev/null 2>&1; then
          echo "      🗑  Papierkorb: ${P/#$HOME/$TILDE}   (gleiches Programm, Version ${V:-?})"
        else
          echo "      ⚠️  nicht verschoben: ${P/#$HOME/$TILDE} – bitte von Hand in den Papierkorb ziehen"
        fi
      else
        echo "      ℹ️  anderes Programm mit gleichem Namen: ${P/#$HOME/$TILDE}   ($ART, ${B:-ohne Kennung})"
      fi
    done
  done
fi

# ---------------------------------------------------------------------------
schritt "Aufräumen: Download-Reste und unnötige Hilfspakete"
brew autoremove >/dev/null 2>&1
brew cleanup --prune=all -s >/dev/null 2>&1
ok "Homebrew-Zwischenspeicher geleert."
FREI_NACHHER=$(frei)
ok "Freier Speicher: vorher $FREI_VORHER → jetzt $FREI_NACHHER"

# ---------------------------------------------------------------------------
schritt "GitHub anmelden"
if gh auth status >/dev/null 2>&1; then
  ok "Du bist bei GitHub schon angemeldet."
else
  cat <<'EOF'
   Gleich passiert Folgendes:
     1. Im Terminal erscheint ein Code wie  ABCD-1234 . Merk ihn dir (oder lass das Fenster offen).
     2. Drücke Enter – der Browser öffnet sich auf github.com.
     3. Falls nötig bei GitHub anmelden, dann den Code eintippen und auf
        „Continue“ und „Authorize github“ klicken.
     4. Zurück ins Terminal – es geht von allein weiter.
EOF
  gh auth login --hostname github.com --git-protocol https --web </dev/tty >&5 2>&6
  if gh auth status >/dev/null 2>&1; then
    gh auth setup-git >/dev/null 2>&1
    ok "GitHub-Anmeldung hat geklappt."
  else
    fehler "GitHub-Anmeldung hat nicht geklappt (kann später wiederholt werden)."
  fi
fi

# ---------------------------------------------------------------------------
schritt "Claude mit deinen Programmen verbinden (MCP-Server)"
if command -v claude >/dev/null 2>&1; then
  bash "$KIT/mcp-setup.sh" || fehler "MCP-Einrichtung hatte Probleme"
else
  fehler "Claude Code fehlt – bitte zuerst bash ~/weiter.sh ausführen."
fi

# ---------------------------------------------------------------------------
echo
if [ -z "$FEHLER" ]; then
  printf '\033[1;32m   🎉 Aufräumen und Einrichtung abgeschlossen!\033[0m\n'
else
  printf '\033[1;33m   Fertig, aber bei diesen Punkten gab es Probleme:\033[0m'
  printf "$FEHLER\n"
  echo "   ➜ Schick die Datei mac-setup-abschluss-protokoll.txt vom Schreibtisch an Claude."
fi
cat <<'EOF'

   Hinweis: „Schach“, „Aktien“ usw. gehören fest zu macOS. Apple erlaubt nicht, sie zu löschen,
   und sie belegen praktisch keinen Platz. Du kannst sie im Launchpad in einen Ordner schieben.

   Letzter Schritt: Terminal schließen (Cmd + Q), neu öffnen und eintippen:   claude

EOF
sleep 1
