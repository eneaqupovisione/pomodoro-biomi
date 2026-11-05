# Pomodoro — istruzioni per gli agenti

Questo foglio è per chi lavora al Pomodoro con un agente (Claude Code, Codex,
Cursor…). Leggi prima [`README.md`](README.md) (cos'è) e, per installarlo,
[`INSTALLA.md`](INSTALLA.md). Il codice, i commenti e l'interfaccia sono in
italiano: scrivi in italiano anche tu, nello stesso stile (frasi corte, i nomi
delle cose, niente gergo), salvo che la persona chieda altro.

## Cos'è, in una riga per parte

- `app/pomodoro.m`: l'app per macOS, Objective-C, un file solo. Conta i secondi con
  l'app che conta davanti, alla soglia apre la pausa: un `NSPanel` non attivante sopra
  ogni finestra di quell'app (o uno per schermo, col modo «tutto il Mac»), con dentro
  una `WKWebView` che carica `biomi/<bioma>.html`.
- Cosa conta e cosa copre lo dice `app` in `impostazioni.json`: niente (Claude),
  un identificativo, una lista, o `"tutto"`. Lo legge `impostazioni`, lo usano
  `appDavanti` e `copri`; la finestra lo cambia con `{tipo: "modo", tutto}`.
- `app/pomodoro.html`: la finestra del Pomodoro. L'app le manda `stato({...})` ogni
  due secondi; la pagina risponde con `window.webkit.messageHandlers.pomodoro.postMessage(...)`.
- `biomi/*.html`: i biomi. **Ogni `.html` in `biomi/` è un bioma** che compare da
  solo nella finestra: non mettere lì pagine di prova.
- `biomi/pausa.js`: tutto quello che i biomi hanno in comune.
- `impostazioni.json` e `dati/`: della persona, mai nel repository (`.gitignore`).

## Costruire

```bash
./costruisci.command
```

Compila con `clang` (servono gli strumenti a riga di comando di Xcode) e firma ad
hoc. L'app è un artefatto: si modifica `app/pomodoro.m`, poi si ricostruisce. I
biomi e `app/pomodoro.html` **non** chiedono di ricostruire: l'app li rilegge ogni
volta che li apre. Se il Pomodoro gira sotto launchd, dopo la ricostruzione:

```bash
launchctl kickstart -k gui/$(id -u)/local.pomodoro.biomi
```

Solo per controllare che compili, senza toccare l'app:

```bash
clang -fsyntax-only -Wall -fobjc-arc app/pomodoro.m
```

## Provare senza finestre (la regola)

**Non aprire finestre, non rubare il primo piano, non coprire lo schermo mentre la
persona lavora.** Una pausa di prova (`--prova`) copre davvero le finestre (col modo
«tutto il Mac», tutti gli schermi): lanciala solo
se la persona lo chiede o dice di sì, e dille prima che succederà.

Quello che si prova senza disturbare:

- **Un bioma, l'aspetto**: Chrome senza schermo, una foto dopo N secondi di tempo
  virtuale. `ora=HH:MM` forza l'ora del giorno, `suono=0` spegne l'audio.

  ```bash
  C="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  "$C" --headless=new --disable-gpu --use-mock-keychain --password-store=basic --no-first-run \
    --user-data-dir=/tmp/pomodoro-chrome --hide-scrollbars --window-size=1280,832 \
    --virtual-time-budget=20000 --screenshot=/tmp/bioma.png "file://$PWD/biomi/stagno.html?suono=0&ora=22:30"
  ```

- **Un bioma, gli errori**: le righe `CONSOLE` su stderr.

  ```bash
  "$C" --headless=new --disable-gpu --use-mock-keychain --password-store=basic --no-first-run \
    --user-data-dir=/tmp/pomodoro-chrome --enable-logging=stderr --v=0 --virtual-time-budget=8000 \
    --dump-dom "file://$PWD/biomi/giardino.html?suono=1" 2>&1 >/dev/null | grep CONSOLE
  ```

- **Dentro una pagina in tempo vero** (un suono decodificato, una variabile):
  `node biomi/fondali/cdp.mjs "<url>" <secondi> "<espressione>" [foto.png]`.
- **La finestra del Pomodoro**: `app/pomodoro.html?finto` la mostra con dati di
  prova, in un browser qualunque o in Chrome senza schermo.
- **L'app, la logica**: un banco di prova. Un file `.m` che fa
  `#define main pomodoro_main` e poi `#include "app/pomodoro.m"`, con una
  sottoclasse di `Pomodoro` che riscrive quello che serve (per esempio `avvisa:`
  che stampa invece di mostrare, `copri` che non copre, `davanti` che dice un'app
  finta: fuori dal ciclo dell'app `frontmostApplication` è vuoto), e `cartella` puntata a una
  cartella finta con la sua `dati/`. Si compila con
  `clang -fobjc-arc -Wno-everything -framework Cocoa -framework WebKit -framework ApplicationServices -framework QuartzCore banco.m -o /tmp/banco`.
  Così si provano il conto, l'avviso, il ritorno a zero, le uscite, senza finestre.
- **I suoni non si provano da soli**: li ascolta la persona, con
  `biomi/fondali/guarda.m` (una finestra normale con suono e tocco, che non prende
  la tastiera), quando vuole lei:

  ```bash
  clang -fobjc-arc -framework Cocoa -framework WebKit biomi/fondali/guarda.m -o /tmp/guarda && /tmp/guarda stagno 5 22:30
  ```

## Il contratto fra l'app e un bioma

L'app apre `biomi/<bioma>.html?fine=<ms epoch>&suono=1|0&uscite=N[&lat=…&lon=…][&musica=<file>]`.

- `fine`: quando finisce la pausa. Il timer lo disegna `pausa.js`; 2,5 secondi prima
  della fine l'audio sfuma, e alla fine deve essere silenzio.
- `suono=0`: le anteprime nella finestra, mute. Una sola copertura suona anche con
  più finestre coperte.
- `uscite`: le pause tolte oggi coi dieci tocchi. Cosa farne lo decide il bioma
  (`OGGI.uscite`).
- `lat`, `lon`: il luogo del sole, da `impostazioni.json`.
- Facoltativi, che l'app di oggi non manda ma lo stagno sa usare (`OGGI` in
  `pausa.js`): `esagerato=0..3` (quanto si è esagerato oggi: da 2 l'acqua si
  intorbida), `studiato=1` (sboccia un loto), `mangiato=0` (le koi salgono a galla a
  chiedere da mangiare). Si provano nel browser (`stagno.html?esagerato=3&studiato=1`)
  o con `guarda stagno 5 12:00 "esagerato=3&studiato=1&mangiato=0"`.
- Nella fascia alta (il timer) e in quella bassa (il respiro), un sesto dell'altezza
  ciascuna, **non passa niente**: l'app scrive «ancora N tocchi per uscire» appena
  sopra la fascia bassa.
- L'app conta i clic per l'uscita prima che arrivino alla pagina: il bioma può usare
  il tocco come vuole.
- Quando la pagina si nasconde, l'audio si zittisce (`visibilitychange`); quando la
  copertura si chiude, l'app svuota la WKWebView.

## Aggiungere un bioma

1. Copia il modello: `cp modello/bioma.html biomi/<nome>.html` e sostituisci `NOME`
   con il nome nei due `<script src>`. Il nome è quello che si vede nella finestra
   (con l'iniziale maiuscola).
2. **Il fondale** (facoltativo): un'immagine 3:2 in pixel art, di giorno, senza bande
   nere e senza le cose che si muovono. Salvala come `biomi/fondali/<nome>-gemini.jpg`
   e lancia `biomi/fondali/impacchetta.sh`, che fa `biomi/fondali/<nome>.js`. Come
   chiederla a un generatore: [`biomi/fondali/LEGGIMI.md`](biomi/fondali/LEGGIMI.md).
   Senza fondale il modello disegna un cielo.
3. **Le animazioni**: nel giro `frame(t)` si parte dai pixel del fondale (`base`),
   si muove quello che vive, poi `colora()` porta la luce del momento (`giorno`,
   `tramonto` da `pausa.js`). La tela è bassa (228 pixel veri) e si allarga: i pixel
   restano pixel (`image-rendering: pixelated`). Guarda come fanno i quattro biomi.
4. **I suoni**: in `fondo = () => {…}`, che `pausa.js` chiama quando parte l'audio.
   Fatti col codice (`rumore`, oscillatori) o registrati: le registrazioni vanno in
   `biomi/suoni/<nome>.js` come `SUONI = { nome: 'data:audio/mp4;base64,…' }`,
   tagliate da `biomi/suoni/impacchetta.sh` (aggiungi lì i tuoi tagli e un
   `pacchetto <nome> …`). Poi `suono('nome')` le decodifica, `ciclo(buf)` le fa girare
   in loop senza cucitura, `colpo(buf, inizio, durata, volume, pan)` ne suona un pezzo.
   Due regole imparate: un sottofondo registrato va preso forte e abbassato, mai preso
   piano e alzato (sale il fruscio); un verso tagliato entra ed esce sfumando.
5. **La musica**: crea `musica/<nome>/`, aggiungi il nome a `musica/brani.js` (o
   rilancia `musica/elenca.sh`).
6. **Provalo** con Chrome senza schermo (sopra), di giorno e di notte (`ora=13:00`,
   `ora=22:30`), e guarda che non ci siano errori in console. Poi chiedi alla persona
   di ascoltarlo con `guarda`, o di provarlo dalla finestra («Provalo · 20 secondi»).

In fondo alla pausa c'è un respiro guidato (`RESPIRO` in `biomi/pausa.js`: inspira 4 s,
trattieni 4, espira 6), uguale in tutti i biomi; la parola cambia in dissolvenza e non
si ingrandisce. Se un giorno si tornasse alle frasi per gli occhi, devono venire da cose
segnate in [`occhi.md`](occhi.md) come «provato» o «consenso».

## Licenze: cosa può entrare nel repository

- **Suoni**: solo CC0 (o licenze che permettono la ridistribuzione, con l'autore in
  `biomi/suoni/LEGGIMI.md`). Controlla la licenza sulla pagina del suono, non fidarti
  del titolo.
- **Musica**: mai nel repository. `musica/**` è in `.gitignore`, tranne `brani.js`,
  `elenca.sh`, `LEGGIMI.md` e i `.gitkeep`. Se aggiungi brani a `brani.js` per una
  persona, ricordale che quel file elenca file che il repository non ha.
- **Immagini di riferimento** per i fondali: solo se chi le ha fatte ne permette
  l'uso.
- **Scaricare un file** (un suono, un brano) chiede prima il sì della persona, con
  nome, fonte e peso.

## Cosa non fare

- Non mettere nel repository `impostazioni.json`, `dati/`, `app/Pomodoro.app`, i
  brani, le registrazioni intere di `biomi/suoni/originali/`.
- Non mettere pagine in `biomi/` che non siano biomi (gli strumenti stanno in `biomi/fondali/`).
- Non togliere il minuto d'avviso, i dieci tocchi o il ritorno a zero dopo 5 minuti
  lontano: sono il patto fra il Pomodoro e chi lo usa.
- Non chiedere permessi nuovi all'app (Accessibilità, registrazione dello schermo)
  senza un motivo che la persona ha accettato: oggi non ne chiede nessuno.
