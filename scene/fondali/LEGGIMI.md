# I fondali dei biomi

Ogni bioma ha un fondale: un'immagine ferma in pixel art, fatta con un generatore
d'immagini (questi quattro con Gemini). Sopra, il codice anima le cose che si
muovono.

| file | cos'è |
|---|---|
| `<bioma>-gemini.jpg` | il fondale com'è uscito dal generatore, 1024×687 (3:2) |
| `<bioma>.js` | lo stesso, impacchettato in `FONDALE = 'data:…'` per la scena |
| `impacchetta.sh` | rifà i `.js` da tutti i `*-gemini.jpg` |
| `guarda.m` | apre un bioma in una finestra normale, con suono e tocco (`guarda giardino 5 22:30`) |
| `foto.m` | fotografa una scena nella WKWebView, come la vede il Pomodoro (apre una finestra quasi invisibile) |
| `cdp.mjs` | apre una scena in Chrome senza schermo e valuta un'espressione dopo N secondi |

Il nome del file conta: `impacchetta.sh` prende ogni `*-gemini.jpg`. Se il tuo
fondale viene da un altro generatore, chiamalo comunque `<bioma>-gemini.jpg`, o
cambia lo script.

## Cosa chiedere al generatore

- **Lo stesso stile per tutti i biomi**: allega un'immagine di riferimento in pixel
  art e chiedi «recreate this… in exactly the same pixel art style». Usa un
  riferimento che puoi usare: fatto da te, o con una licenza che lo permette.
- **3:2, a tutta immagine**: è la forma dello schermo di un Mac. Scrivi
  esplicitamente «NO black bars at the top or bottom», sennò le mette.
- **Niente di quello che si muove**: niente pesci, rane o foglie a galla, niente
  foglie in aria, niente gocce sul vetro. Le disegna il codice.
- **Una sola versione, di giorno.** Chiedere la notte modificando l'immagine del
  giorno non funziona: il generatore ridisegna la scena, e le due non combaciano.
  Giorno, tramonto e notte si fanno col filtro (`colora()` nella scena) più le luci
  del codice, come le lanterne del giardino.

Poi: copia l'immagine qui come `<bioma>-gemini.jpg` e lancia `./impacchetta.sh`.

## Come la scena lo usa

`caricaFondale(FONDALE, FW, FH)`, in `../pausa.js`, fa tre cose:
- ritaglia l'immagine per coprire la tela;
- la rimpicciolisce facendo la media: ogni pixel del generatore è un quadretto di
  circa 3 pixel, quindi la griglia vera è circa 341×229 e la tela è alta 228;
- riduce i colori a 40 (k-means), tranne gli accenti (luci, fiori), che restano
  com'erano.

Ci mette circa 60 ms. Le parti si riconoscono dal colore: nel giardino il rosso
fitto è la chioma, il grigio la ghiaia, il giallo caldo le lanterne.

Perché il `.js` e non il `.jpg` diretto: una pagina aperta da file non può
leggere i pixel di un'immagine letta da file (`SecurityError`), di un `data:` sì.

## Fotografare una scena, senza finestre

Le prove si fanno con **Chrome senza schermo**: nessuna finestra, nessun primo
piano rubato a chi sta lavorando, un profilo a parte, niente portachiavi.

```bash
C="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
P=(--headless=new --disable-gpu --use-mock-keychain --password-store=basic --no-first-run --user-data-dir=/tmp/pomodoro-chrome)
# una foto dopo 40 s di scena (tempo virtuale: ci mette pochi secondi)
"$C" $P --hide-scrollbars --window-size=1280,832 --virtual-time-budget=40000 --screenshot=/tmp/notte.png "file://$PWD/scene/pioggia.html?suono=0&ora=21:30"
# gli errori della pagina: righe CONSOLE su stderr
"$C" $P --enable-logging=stderr --v=0 --virtual-time-budget=8000 --dump-dom "file://$PWD/scene/giardino.html?suono=1" 2>&1 >/dev/null | grep CONSOLE
```

(Da lanciare con zsh nella radice del progetto. Sul Mac `timeout` non esiste: non
serve, il tempo virtuale finisce da solo.) Chrome riduce il fondale con un motore
diverso da quello del Pomodoro (Safari): l'aspetto è lo stesso, ma per esempio
trova più finestre accese.

**Per guardare dentro una pagina che gira in tempo vero** (per esempio se un suono
si è decodificato) c'è `cdp.mjs` (Node 22 o più, per `WebSocket`):
`node scene/fondali/cdp.mjs "file://$PWD/scene/pioggia.html?suono=1" 6 "!!vetroBuf"`.

**I suoni non si controllano così**: li ascolta una persona, con `guarda`
(si apre davanti ma non prende la tastiera):

```bash
clang -fobjc-arc -framework Cocoa -framework WebKit scene/fondali/guarda.m -o /tmp/guarda
/tmp/guarda stagno 5 22:30
```
