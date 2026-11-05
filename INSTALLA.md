# Installare il Pomodoro

Cinque minuti, una volta. Ogni comando va lanciato nella cartella del progetto.
Se lo fa un agente per te, gli basta questo foglio e [`AGENTS.md`](AGENTS.md).

## 1. Cosa serve

```bash
xcode-select --install
```

(Se dice che sono già installati, va bene.) Facoltativi: l'app desktop di Claude
(per il modo di base), `brew install ffmpeg` (per la musica), Python 3 (per l'hook).

## 2. Scaricarlo

```bash
git clone https://github.com/eneaqupovisione/pomodoro-biomi.git ~/pomodoro
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
- `bioma`: il nome di un file di `biomi/` senza `.html`.
- `oggi`: minuti diversi solo per una data,
  `{"data": "2026-11-05", "lavoro_minuti": 30, "pausa_minuti": 5}`.
- `app`: cosa conta e cosa copre la pausa (si sceglie anche dalla finestra, «Cosa
  conta, cosa copre»):
  - senza `app`, o `"com.anthropic.claudefordesktop"`: solo Claude, e la pausa copre
    solo le sue finestre;
  - `"tutto"`: qualunque app conta, e la pausa copre tutti gli schermi;
  - un'altra app, o una lista (`["com.apple.Preview", "com.apple.Safari"]`): contano
    quelle, e la pausa copre le loro finestre. L'identificativo di un'app:
    `osascript -e 'id of app "Anteprima"'`.
- `spento_fino`: lo scrive «Spegni»; toglierlo riaccende.

L'app le rilegge ogni secondo: non serve ricostruire.

## 5. La musica (facoltativa)

I brani non sono inclusi: la loro licenza non permette di ridistribuirli. Per ogni
bioma ci sono quelli scelti, coi link alle pagine di Pixabay e il nome del file che
si scarica: [`musica/stagno/LEGGIMI.md`](musica/stagno/LEGGIMI.md),
[`giardino`](musica/giardino/LEGGIMI.md), [`pioggia`](musica/pioggia/LEGGIMI.md),
[`mare`](musica/mare/LEGGIMI.md). Scaricali dal browser, spostali in
`musica/<bioma>/`, poi:

```bash
musica/elenca.sh
```

Dettagli (volume, velocità, brani tuoi): [`musica/LEGGIMI.md`](musica/LEGGIMI.md).

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

## 7. Farlo diventare un'app come le altre

Dopo `./installa.sh` il Pomodoro c'è sempre: parte all'accesso e vive nella barra in
alto. Per aprirlo come un'app qualunque:

- **Sulla scrivania o in Applicazioni**: trascina `app/Pomodoro.app` tenendo
  premuti ⌘ e ⌥: si crea un **alias**. Non copiare né spostare l'app: trova la sua
  cartella da dove sta (i biomi, la musica, le impostazioni sono accanto a lei).
  Un alias in `~/Applications` lo mette accanto alle altre app.
- **Nel Dock**: trascina `app/Pomodoro.app` nel Dock.
- Il doppio clic apre la finestra. Se il Pomodoro gira già, chiede a quello acceso
  di aprirla, e se ne va: ce n'è sempre uno solo.

**I permessi.** Il Pomodoro non ne chiede: niente Accessibilità, niente
registrazione dello schermo. Legge dove stanno le finestre (non cosa c'è dentro),
da quanto non tocchi tastiera e mouse, e quale app è davanti, e per tutto questo
macOS non chiede niente. Le cose che può mostrarti macOS:

- dopo `./installa.sh`, la notifica «Elemento in background aggiunto»: è il
  LaunchAgent. Lo trovi in Impostazioni di Sistema → Generali → Elementi login ed
  estensioni, sotto «Consenti in background»; lascialo acceso, o il Pomodoro non
  parte all'accesso;
- niente avvisi di Gatekeeper: l'app la costruisci tu, sul tuo Mac, quindi macOS
  non la tratta come un'app scaricata. Per questo il repository non contiene
  un'app già costruita, e non conviene usarne una costruita da altri.

**Se aggiungi tu qualcosa che chiede un permesso** (per esempio leggere quale chat
è aperta in un'app, che chiede l'Accessibilità): con la firma ad hoc ogni
ricostruzione è un'app nuova per macOS, e il permesso salta a ogni
`./costruisci.command`. Per tenerlo, firma sempre con lo stesso certificato:

1. Accesso Portachiavi → menu Accesso Portachiavi → Assistente Certificato → Crea
   un certificato…; un nome (per esempio «Pomodoro locale»), identità «Radice
   autofirmata», tipo di certificato «Firma del codice».
2. Costruisci con quel nome:

   ```bash
   POMODORO_FIRMA="Pomodoro locale" ./installa.sh
   ```

3. Dai il permesso una volta, in Impostazioni di Sistema → Privacy e sicurezza.
   Resta anche dopo le ricostruzioni.

## 8. Provarlo

Una pausa di prova di 20 secondi, come quella vera (sopra Claude, o su tutto lo
schermo col modo «tutto il Mac»), che non tocca il conto né segna uscite:

```bash
app/Pomodoro.app/Contents/MacOS/Pomodoro --prova 20 --bioma mare
```

O dalla finestra: «Provalo · 20 secondi» sotto ogni bioma. Dieci tocchi la
chiudono prima.

## Se qualcosa non va

- **Il 🍅 non c'è**: `launchctl print gui/$(id -u)/local.pomodoro.biomi` e
  `dati/errori.log`.
- **Il conto non sale**: conta solo con l'app che conta davanti (di base Claude) e
  le mani sul Mac. Scegli «tutto il Mac» nella finestra, o metti le tue app in `app`.
- **La pausa non copre**: le finestre più piccole di 300×200 punti non si coprono.
