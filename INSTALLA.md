# Installare il Pomodoro

Cinque minuti, una volta. Ogni comando va lanciato nella cartella del progetto.
Se lo fa un agente per te, gli basta questo foglio e [`AGENTS.md`](AGENTS.md).

## 1. Cosa serve

```bash
xcode-select --install
```

(Se dice che sono già installati, va bene.) Serve anche l'app desktop di Claude.
Facoltativi: `brew install ffmpeg` (per la musica), Python 3 (per l'hook).

## 2. Scaricarlo

```bash
git clone <indirizzo di questo repository> ~/pomodoro
```

```bash
cd ~/pomodoro
```

La cartella può stare dove vuoi: l'app la trova da sola (è la cartella sopra
`app/Pomodoro.app`). Se poi la sposti, rilancia `./installa.sh`.

## 3. Costruirlo e accenderlo

```bash
./installa.sh
```

Costruisce `app/Pomodoro.app`, crea `impostazioni.json` da
`impostazioni.esempio.json` se non c'è, e mette un LaunchAgent in
`~/Library/LaunchAgents/local.pomodoro.biomi.plist`: il Pomodoro parte a ogni
accesso, e riparte se si rompe (non se lo chiudi con Esci). Il 🍅 compare nella
barra in alto.

Solo costruirlo, senza farlo partire all'accesso: `./costruisci.command`, poi
doppio clic su `app/Pomodoro.app`.

Dopo ogni modifica a `app/pomodoro.m`:

```bash
./costruisci.command && launchctl kickstart -k gui/$(id -u)/local.pomodoro.biomi
```

Toglierlo dall'accesso: `./installa.sh --togli`.

## 4. Le impostazioni

`impostazioni.json` (le scrive anche la finestra del Pomodoro):

```json
{
  "lavoro_minuti": 45,
  "pausa_minuti": 5,
  "bioma": "stagno",
  "luogo": { "lat": 41.9, "lon": 12.5 },
  "oggi": null
}
```

- `luogo`: latitudine e longitudine per il sole dei biomi (giorno, tramonto e notte
  veri). Bastano due decimali, la città basta. Senza, Roma.
- `bioma`: il nome di un file di `scene/` senza `.html`.
- `oggi`: minuti diversi solo per una data,
  `{"data": "2026-11-05", "lavoro_minuti": 30, "pausa_minuti": 5}`.
- `app` (facoltativa): l'identificativo dell'app da contare e coprire. Di base
  `com.anthropic.claudefordesktop`. Per trovare quello di un'altra app:
  `osascript -e 'id of app "Nome"'`.
- `spento_fino`: lo scrive «Spegni»; toglierlo riaccende.

L'app le rilegge ogni secondo: non serve ricostruire.

## 5. La musica (facoltativa)

I brani non sono inclusi. Mettili in `musica/<bioma>/`, poi:

```bash
musica/elenca.sh
```

Dettagli e brani consigliati: [`musica/LEGGIMI.md`](musica/LEGGIMI.md).

## 6. La seconda sicura per Claude Code (facoltativa)

La copertura ferma la tastiera, ma un messaggio può partire lo stesso (da un'altra
finestra, dal terminale). `hook.py` è un hook `UserPromptSubmit` di Claude Code:
in pausa ferma il messaggio e dice quanto manca. Va in `~/.claude/settings.json`,
col percorso vero della cartella:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "hooks": [{ "type": "command", "command": "python3 \"$HOME/pomodoro/hook.py\"" }] }
    ]
  }
}
```

Se `settings.json` ha già degli hook, si aggiunge la voce accanto alle altre. Se
qualcosa si rompe, l'hook lascia passare il messaggio.

## 7. Provarlo

Una pausa di prova di 20 secondi, sopra Claude, che non tocca il conto né segna
uscite:

```bash
app/Pomodoro.app/Contents/MacOS/Pomodoro --prova 20 --bioma mare
```

O dalla finestra: «Provalo · 20 secondi» sotto ogni bioma. Dieci tocchi la
chiudono prima.

## Se qualcosa non va

- **Il 🍅 non c'è**: `launchctl print gui/$(id -u)/local.pomodoro.biomi` e
  `dati/errori.log`.
- **Il conto non sale**: conta solo con l'app di Claude davanti e le mani sul Mac.
  Se usi un'altra app, mettila in `app`.
- **La pausa non copre**: le finestre più piccole di 300×200 punti non si coprono.
