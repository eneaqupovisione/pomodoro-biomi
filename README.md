# Pomodoro 🍅

> **In English, briefly.** A pomodoro timer for macOS with pixel-art *biomes*.
> After 45 minutes of work, a biome (a koi pond, a zen garden, rain on a window,
> the sea at dusk) covers your screen for 5 minutes and takes the keyboard, so you
> look away and rest your eyes. It was born for the Claude desktop app (it can
> cover only Claude's windows while Claude keeps working underneath), but it works
> for the whole Mac too, or for studying. The interface, the code and these docs
> are in Italian; any LLM coding agent can read them and set it up for you. Start
> from [`INSTALLA.md`](INSTALLA.md), or point your agent at [`AGENTS.md`](AGENTS.md).

Un pomodoro per il Mac. Dopo **45 minuti** di lavoro, **5 minuti di pausa**: un
**bioma** in pixel art copre lo schermo e si prende la tastiera, così ti fermi
davvero e guardi altrove. Un minuto prima compare un avviso in alto a destra, «Tra
un minuto, la pausa.». Dieci tocchi di fila sulla pausa la tolgono prima, e
l'uscita resta segnata.

È nato per l'app di Claude, e di base copre **solo le finestre di Claude**: non
puoi scrivere, approvare né leggere, ma Claude continua a lavorare sotto e il resto
del Mac resta libero. Con un clic conta e copre **tutto il Mac**: per lo studio, o
per il computer in generale. Oppure solo le app che scegli tu.

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

## Tre modi di usarlo

Si sceglie nella finestra del Pomodoro, «Cosa conta, cosa copre», o in
`impostazioni.json` (`app`, in [`INSTALLA.md`](INSTALLA.md)).

**Con Claude** (com'è nato, ed è il modo di base). Conta solo il tempo con l'app di
Claude davanti e le mani sul Mac; la pausa copre le sue finestre e le segue. Le
sessioni sotto continuano: quando torni, hanno lavorato per te. Se vuoi che in
pausa non parta proprio niente, nemmeno da un terminale, c'è l'hook per Claude Code
([`INSTALLA.md`](INSTALLA.md), punto 6). Il resto del Mac resta libero: in pausa
puoi guardare un film, leggere, rispondere a un messaggio, ma non continuare con
Claude.

**Tutto il Mac**. Conta qualunque app, e la pausa copre tutti gli schermi (la barra
in alto e il Dock restano, così il 🍅 dice quanto manca). È il pomodoro classico,
per chi passa la giornata al computer.

**Per lo studio**. «Tutto il Mac», o solo le app dello studio (il lettore dei PDF,
il browser, le note: `"app": ["com.apple.Preview", "com.apple.Safari"]`), e i tempi
che preferisci: 25 + 5 è il pomodoro di sempre, 50 + 10 per le sessioni lunghe.
«Solo oggi» cambia i tempi per una giornata sola (il giorno prima di un esame) e da
domani tornano quelli di sempre. Durante una lezione online o una videochiamata,
«spegni per un'ora».

Qualche abitudine che aiuta:
- **Pausa adesso**, dal menu del 🍅, quando finisci un pezzo prima del tempo: la
  pausa parte subito, e il conto riparte dopo.
- **I biomi si provano** dalla finestra («Provalo · 20 secondi»): sceglierne uno è
  metà del piacere.
- **Lontano più di 5 minuti** (un'altra app, lo schermo spento, fermo) il conto
  riparte da zero: una pausa vera fatta da te vale come quella del Pomodoro.
- **Le uscite** coi dieci tocchi restano segnate, e la finestra le conta: se sono
  tante, forse i tempi sono troppo stretti.

## Come si usa

- **La barra in alto**: `🍅 38'` sono i minuti che mancano, in pausa `🍅 3:12`. Dal
  menu del 🍅: Pausa adesso, Apri il Pomodoro, Spegni per un'ora, Riaccendi,
  Ricomincia il conto, Apri la cartella, Esci.
- **La finestra** (doppio clic su `app/Pomodoro.app`, o «Apri il Pomodoro»): i
  minuti di lavoro e di pausa, **solo per oggi** o **da adesso in poi**; cosa conta
  e cosa copre; il bioma, ognuno con la sua anteprima viva e «Provalo · 20 secondi»
  (una pausa di prova come quella vera, che non tocca il conto); spegnerlo «per
  un'ora» o «fino a stasera»; la giornata (le pause fatte, le uscite).
- **Cosa conta**: i secondi in cui l'app che conta è davanti e tocchi tastiera o
  mouse (fermo da più di 2 minuti non conta). Coperchio chiuso, schermo spento o
  bloccato non contano mai.
- **Fuori dal lavoro non lavora**: il giro di ogni secondo gira solo quando serve.
- **In pausa**, con Claude (o con le tue app), il bioma copre ogni loro finestra e
  la segue; col mouse ai bordi si ritira di mezzo centimetro e si vede la finestra
  sotto. Se torni su quell'app (clic, ⌘Tab), la tastiera torna al bioma.
- **L'uscita**: dieci tocchi di fila (al più 1,2 secondi fra uno e l'altro). Dal
  quarto tocco lo dice: «ancora N tocchi per uscire · resterà segnato». Ogni
  uscita va in `dati/uscite.jsonl`.

## Cosa serve

- macOS 12 o più recente, con gli strumenti a riga di comando di Xcode (`clang`):
  `xcode-select --install`.
- Facoltativi: l'app desktop di Claude (per il modo di base), `ffmpeg` per misurare
  i brani e rifare i suoni, Python 3 per l'hook, Google Chrome per le prove senza
  finestre.

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
| `modello/bioma.html` | un bioma minimo, da copiare per farne uno tuo |
| `musica/` | i brani, che aggiungi tu ([`LEGGIMI.md`](musica/LEGGIMI.md)) |
| `costruisci.command` | costruisce `app/Pomodoro.app` |
| `installa.sh` | costruisce e fa partire il Pomodoro a ogni accesso |
| `hook.py` | la seconda sicura, per Claude Code |
| `impostazioni.json` | i tuoi tempi, il modo, il bioma, il luogo (nasce da `impostazioni.esempio.json`) |
| `dati/` | lo stato e i registri: `stato.json`, `pause.jsonl`, `uscite.jsonl`, `errori.log` |

Installazione, e come farlo diventare un'app come le altre: [`INSTALLA.md`](INSTALLA.md).
Per chi ci lavora (persone e agenti): [`AGENTS.md`](AGENTS.md).

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
