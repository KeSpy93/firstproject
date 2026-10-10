# Globale Anweisungen für Claude Code (~/.claude/CLAUDE.md)

## Über mich
- Sprache: Deutsch in Antworten; Code, Kommentare und Commit-Messages auf Englisch.
- Rechner: MacBook (macOS, Apple Silicon), Shell: zsh, Paketmanager: Homebrew.

## Arbeitsweise
- Projekte liegen unter `~/Projects/{apps,games,cad,tools,simulation,design}`.
- Vor größeren Änderungen kurz den Plan nennen; bei destruktiven Aktionen (löschen, force-push, Systemänderungen) nachfragen.
- Neue Projekte immer mit `git init`, `.gitignore` und README anlegen; große Binärdateien über Git LFS.
- Secrets nie in Dateien im Repo schreiben – sie liegen in `~/.claude/secrets.env`.

## Werkzeuge
- Blender: per MCP-Server `blender` (Add-on muss in Blender verbunden sein) oder headless:
  `/Applications/Blender.app/Contents/MacOS/Blender -b -P script.py`
- Unreal Engine: Projekte unter `~/Projects/games`, Builds über `RunUAT.sh` der installierten Engine.
- iOS/macOS: `xcodebuild` bzw. MCP-Server `xcodebuild`.
- Web-Apps im Browser testen: MCP-Server `playwright`.
- Bibliotheks-Doku nachschlagen: MCP-Server `context7`.
