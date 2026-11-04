#!/bin/zsh
# Costruisce l'app e la fa partire a ogni accesso (un LaunchAgent dell'utente).
#   ./installa.sh           costruisce, installa il LaunchAgent e lo accende
#   ./installa.sh --togli   spegne e toglie il LaunchAgent (la cartella resta com'è)
# Il LaunchAgent punta a questa cartella: se la sposti, rilancia ./installa.sh.
set -e
cd "${0:A:h}"
QUI=$(pwd)
ETICHETTA=local.pomodoro.biomi
AGENTE=~/Library/LaunchAgents/$ETICHETTA.plist

launchctl bootout gui/$(id -u)/$ETICHETTA 2>/dev/null || true
if [[ $1 == --togli ]]; then
  rm -f $AGENTE
  echo "Tolto: il Pomodoro non parte più all'accesso."
  exit 0
fi

./costruisci.command
mkdir -p dati ~/Library/LaunchAgents
[[ -f impostazioni.json ]] || cp impostazioni.esempio.json impostazioni.json
cat > $AGENTE <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$ETICHETTA</string>
  <key>ProgramArguments</key>
  <array><string>$QUI/app/Pomodoro.app/Contents/MacOS/Pomodoro</string></array>
  <key>RunAtLoad</key><true/>
  <!-- Riparte se si rompe, non se lo chiudi con «Esci» -->
  <key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
  <key>StandardErrorPath</key><string>$QUI/dati/errori.log</string>
</dict>
</plist>
PLIST
launchctl bootstrap gui/$(id -u) $AGENTE
echo "Acceso: il 🍅 è nella barra in alto, e ripartirà a ogni accesso."
