# Pomodoro 🍅

> **In English, briefly.** A pomodoro timer for the Claude desktop app on macOS.
> After 45 minutes with Claude in front of you, a pixel-art *biome* (a koi pond, a
> zen garden, rain on a window, the sea at dusk) covers Claude's window for 5
> minutes and takes the keyboard, so you look away and rest your eyes. The rest of
> the Mac stays free, and Claude keeps working underneath. The interface, the code
> and these docs are in Italian; any LLM coding agent can read them and set it up
> for you. Start from [`INSTALLA.md`](INSTALLA.md), or point your agent at
> [`AGENTS.md`](AGENTS.md).

Il pomodoro di Claude. Dopo **45 minuti** di Claude, **5 minuti di pausa**: un
**bioma** in pixel art copre la finestra di Claude e si prende la tastiera, così
non puoi scrivere, approvare né leggere. Le sessioni sotto continuano a lavorare,
e il resto del Mac resta libero. Un minuto prima compare un avviso in alto a
destra, «Tra un minuto, la pausa.». Dieci tocchi di fila sulla pausa la tolgono
prima, e l'uscita resta segnata.

Perché 45 e 5, e perché gli inviti in fondo alla pausa dicono quello che dicono
(5 minuti ogni ora riducono dolore agli occhi e al collo; davanti allo schermo si
ammicca un terzo del normale; guardare lontano scioglie la messa a fuoco; luce blu
e modalità scura sono miti): [`occhi.md`](occhi.md), con le fonti.

## I biomi

| bioma | cosa c'è | cosa puoi fare |
|---|---|---|
| **stagno** | quattro koi che si evitano, la rana che salta fra le ninfee e a volte si mangia la libellula, foglie che cadono; di notte luna e lucciole | toccare l'acqua: si fanno i cerchi e le koi vengono a vedere; toccare la rana: salta |
| **giardino** | un giardino zen con l'acero rosso, le foglie che cadono, le lanterne accese di notte; kodama di giorno, onibi di notte | rastrellare la ghiaia col dito |
| **pioggia** | una città dietro un vetro appannato, gocce che scivolano, finestre che si accendono, lampi lontani | pulire il vetro col dito |
| **mare** | la riva dall'alto, onde che salgono a tempo col suono, granchi e ombre di gabbiani; di notte la schiuma azzurra | scrivere sulla sabbia: l'onda cancella |

**Il giorno e la notte sono veri**: l'altezza del sole sul tuo luogo
(`impostazioni.json`, `luogo`), calcolata senza rete. I suoni sono registrazioni
CC0 da Freesound più qualche suono fatto dal codice; i fondali sono fatti con un
generatore d'immagini, e sopra il codice anima tutto il resto. La musica la
aggiungi tu ([`musica/LEGGIMI.md`](musica/LEGGIMI.md)).

## Come si usa

- **La barra in alto**: `🍅 38'` sono i minuti che mancano, in pausa `🍅 3:12`. Dal
  menu del 🍅: Pausa adesso, Apri il Pomodoro, Spegni per un'ora, Riaccendi,
  Ricomincia il conto, Apri la cartella, Esci.
- **La finestra** (doppio clic su `app/Pomodoro.app`, o «Apri il Pomodoro»): i
  minuti di lavoro e di pausa, **solo per oggi** o **da adesso in poi**; il bioma,
  ognuno con la sua anteprima viva e «Provalo · 20 secondi» (una pausa di prova,
  sopra Claude come quella vera, che non tocca il conto); spegnerlo «per un'ora» o
  «fino a stasera»; la giornata (le pause fatte, le uscite).
- **Cosa conta**: i secondi in cui Claude è in primo piano e tocchi tastiera o
  mouse (fermo da più di 2 minuti non conta). Coperchio chiuso, schermo spento o
  bloccato non contano mai. **Più di 5 minuti lontano da Claude** (un'altra app, lo
  schermo spento, fermo) e il conto riparte da zero; sotto i 5 minuti riprende da
  dove era.
- **Fuori da Claude non lavora**: il giro di ogni secondo gira solo con Claude
  davanti, in pausa o con la finestra del Pomodoro in vista.
- **In pausa** il bioma copre ogni finestra di Claude e la segue. Col mouse ai
  bordi si ritira di mezzo centimetro e si vede Claude sotto. Se torni su Claude
  (clic, ⌘Tab), la tastiera torna al bioma.
- **L'uscita**: dieci tocchi di fila (al più 1,2 secondi fra uno e l'altro). Dal
  quarto tocco lo dice: «ancora N tocchi per uscire · resterà segnato». Ogni
  uscita va in `dati/uscite.jsonl`.
- **La seconda sicura** (facoltativa): un hook di Claude Code che, in pausa, ferma i
  messaggi che riescono comunque a partire ([`INSTALLA.md`](INSTALLA.md)).

## Cosa serve

- macOS 12 o più recente, con gli strumenti a riga di comando di Xcode (`clang`):
  `xcode-select --install`.
- L'app desktop di Claude (o un'altra app da coprire: `app` in `impostazioni.json`).
- Facoltativi: `ffmpeg` per misurare i brani e rifare i suoni, Python 3 per l'hook,
  Google Chrome per le prove senza finestre.

L'app non chiede permessi: legge solo dove stanno le finestre, non cosa c'è dentro.

## Come è fatto

| | |
|---|---|
| `app/pomodoro.m` | l'app (Objective-C, un file solo): il conto, le coperture, il menu, la finestra |
| `app/pomodoro.html` | la finestra del Pomodoro, riletta a ogni apertura |
| `scene/*.html` | i biomi: ogni `.html` qui dentro è un bioma sceglibile |
| `scene/pausa.js` | quello che i biomi hanno in comune: il sole, il timer, gli inviti, l'audio, la musica |
| `scene/fondali/` | i fondali e gli strumenti per provarli ([`LEGGIMI.md`](scene/fondali/LEGGIMI.md)) |
| `scene/suoni/` | i suoni registrati, tagliati e impacchettati ([`LEGGIMI.md`](scene/suoni/LEGGIMI.md), con le fonti) |
| `musica/` | i brani, che aggiungi tu ([`LEGGIMI.md`](musica/LEGGIMI.md)) |
| `costruisci.command` | costruisce `app/Pomodoro.app` |
| `installa.sh` | costruisce e fa partire il Pomodoro a ogni accesso |
| `hook.py` | la seconda sicura, per Claude Code |
| `impostazioni.json` | i tuoi tempi, il bioma, il luogo (nasce da `impostazioni.esempio.json`) |
| `dati/` | lo stato e i registri: `stato.json`, `pause.jsonl`, `uscite.jsonl`, `errori.log` |

Installazione: [`INSTALLA.md`](INSTALLA.md). Per chi ci lavora (persone e
agenti): [`AGENTS.md`](AGENTS.md).

## Licenze

- **Il codice**: MIT, in [`LICENSE`](LICENSE).
- **I suoni** in `scene/suoni/*.js`: tratti di registrazioni **CC0** di
  [Freesound](https://freesound.org), elencate con gli autori in
  [`scene/suoni/LEGGIMI.md`](scene/suoni/LEGGIMI.md).
- **I fondali** in `scene/fondali/`: generati con Gemini; per quanto possano avere
  una licenza, sono offerti come CC0.
- **Il carattere** Silkscreen (timer e inviti) arriva da Google Fonts, con licenza
  SIL Open Font License.
- **La musica** non è inclusa.
