#!/usr/bin/env bash
# Frühere Einstiegsdatei. Die Einrichtung macht jetzt weiter.sh: Es prüft den
# Stand, repariert und installiert nur, was fehlt – beim ersten Mal genauso wie
# nach einem Abbruch.
cp "$(dirname "$0")/weiter.sh" "$HOME/weiter.sh"
exec bash "$HOME/weiter.sh"
