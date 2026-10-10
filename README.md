# firstproject – Mac-Setup für die Arbeit mit Claude

Mit diesem Kit richtest du dein MacBook so ein, dass Claude Code dort mit deinen Tools arbeiten kann:
Programmierung, App- und Spieleentwicklung, 3D/CAD, Grafikdesign, Simulation und Online-Dienste über MCP-Server.

```
mac-setup/
├── Brewfile              # alle Programme (Homebrew)
├── setup.sh              # Grundinstallation + Claude Code + globale Konfiguration
├── mcp-setup.sh          # MCP-Server für Claude Code einrichten
├── secrets.env.example   # Vorlage für API-Tokens (landet in ~/.claude/, nie im Repo)
└── claude/
    ├── settings.json     # Berechtigungen für Claude Code  → ~/.claude/settings.json
    └── CLAUDE.md         # globale Anweisungen für Claude  → ~/.claude/CLAUDE.md
```

## 1. Repo auf den Mac holen

```bash
git clone https://github.com/KeSpy93/firstproject.git ~/Projects/firstproject
cd ~/Projects/firstproject
```

## 2. Grundinstallation

```bash
bash mac-setup/setup.sh
```

Das Skript installiert die Xcode Command Line Tools, Homebrew, alle Programme aus dem `Brewfile` und Claude Code.
Außerdem legt es `~/.claude/settings.json` und `~/.claude/CLAUDE.md` an.
Programme, die du nicht brauchst, kommentierst du vorher im `Brewfile` mit `#` aus.

Danach:

```bash
claude          # einmal starten und mit deinem Claude-Konto anmelden
gh auth login   # GitHub anmelden
```

**Manuell zu installieren:**
- **Unreal Engine:** Epic Games Launcher öffnen → *Unreal Engine* → *Bibliothek* → Engine-Version hinzufügen (ca. 50–100 GB).
- **Xcode:** wird über `mas` installiert, wenn du im App Store angemeldet bist; sonst direkt aus dem App Store laden.
  Danach einmal öffnen und die Lizenz bestätigen (`sudo xcodebuild -license accept`).

## 3. Tokens hinterlegen

```bash
cp mac-setup/secrets.env.example ~/.claude/secrets.env
chmod 600 ~/.claude/secrets.env
open -e ~/.claude/secrets.env   # GITHUB_PAT eintragen
```

## 4. MCP-Server einrichten

```bash
bash mac-setup/mcp-setup.sh
```

| Server | Wofür | Voraussetzung |
|---|---|---|
| `filesystem` | Dateien in ~/Projects, Dokumente, Desktop, Downloads | – |
| `memory` | Langzeit-Notizen über Sitzungen hinweg | – |
| `sequential-thinking` | strukturiertes Lösen großer Aufgaben | – |
| `context7` | aktuelle Doku zu Bibliotheken und Frameworks | – |
| `playwright` | Browser steuern, Web-Apps testen | – |
| `github` | Repos, Issues, PRs | `GITHUB_PAT` |
| `xcodebuild` | iOS/macOS-Apps bauen, Simulator | Xcode |
| `blender` | Blender per Prompt steuern | Blender-Add-on (siehe unten) |
| `figma` | Designs aus Figma lesen | Figma Desktop, Dev Mode MCP aktiviert |
| `notion`, `linear`, `sentry` | Online-Dienste | in Claude Code `/mcp` → anmelden |

**Blender verbinden:**
1. `addon.py` von <https://github.com/ahujasid/blender-mcp> herunterladen.
2. Blender → *Edit → Preferences → Add-ons → Install from Disk* → `addon.py` auswählen und aktivieren.
3. In der 3D-Ansicht `N` drücken → Reiter *BlenderMCP* → *Connect to Claude*.

**Figma verbinden:** Figma Desktop → Menü → *Preferences → Enable Dev Mode MCP Server*.

**Google, Gmail, Canva & Co.:** Diese Dienste verbindest du auf claude.ai unter *Einstellungen → Connectors*.
Sie stehen dann in Claude Desktop und in Claude Code zur Verfügung, solange du mit demselben Konto angemeldet bist.

### MCP für Engines & CAD (Community-Projekte, manuell)

Für diese Programme gibt es noch keine offiziellen MCP-Server. Die Community-Plugins entwickeln sich schnell.
Installiere sie erst, wenn du sie für ein Projekt brauchst, und richte sie dann nach der jeweiligen README ein:

- **Unreal Engine:** z. B. `chongdashu/unreal-mcp` (Plugin ins UE-Projekt kopieren plus Python-Server)
- **Unity:** z. B. `CoplayDev/unity-mcp` (Paket über den Unity Package Manager)
- **Godot:** z. B. `Coding-Solo/godot-mcp`
- **FreeCAD:** z. B. `neka-nat/freecad-mcp` (FreeCAD-Add-on plus `uvx freecad-mcp`)

Einbinden geht immer nach demselben Muster:

```bash
claude mcp add --scope user <name> -- <startbefehl>
```

## 5. macOS-Berechtigungen

Unter *Systemeinstellungen → Datenschutz & Sicherheit* für **Terminal** bzw. **iTerm** (und die **Claude**-App) freigeben:

| Berechtigung | Wofür |
|---|---|
| Festplattenvollzugriff | Zugriff auf Dokumente, Desktop, iCloud-Ordner ohne Rückfragen |
| Bedienungshilfen | Apps per AppleScript/Automation steuern |
| Bildschirmaufnahme | Screenshots, damit Claude Ergebnisse sehen kann |
| Automation | Steuerung einzelner Apps (fragt macOS beim ersten Mal) |

Danach das Terminal neu starten.

## 6. Arbeiten

```bash
cd ~/Projects/games/mein-spiel
claude
```

- `/mcp` zeigt den Status der MCP-Server.
- `/permissions` passt die Freigaben an. Gefährliche Befehle (`rm`, `sudo`, `git push`, `brew install`) fragen immer nach.
- **Vom Handy oder aus der Claude-App steuern:** `claude remote-control` im Projektordner starten.
  Die Sitzung läuft dann auf dem Mac und ist zusätzlich in der Claude-Code-App erreichbar.

## Sicherheit

- Tokens nur in `~/.claude/secrets.env` ablegen, nie in Repos.
- Online-Dienste über OAuth bzw. Connectors anmelden, nie Passwörter an Claude geben.
- `settings.json` sperrt standardmäßig `~/.ssh`, `.env`-Dateien und `secrets.env` für Claude.
- Den Filesystem-Server nur für Ordner freigeben, die Claude wirklich braucht (`PROJECTS_DIR`).
