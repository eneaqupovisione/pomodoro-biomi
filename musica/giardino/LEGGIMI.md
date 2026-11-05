# La musica del giardino

L'aria: raccolto, sacro, un po' misterioso: shakuhachi, tempio. Lenta e semplice, senza batteria né voce.

I brani non sono in questa cartella: sono su Pixabay Music, gratis, ma la loro
licenza non lascia ridistribuirli così come sono. Si scaricano in un minuto.

## I brani

| brano | autore | il file che scarichi |
|---|---|---|
| [Zen Temple](https://pixabay.com/music/ambient-zen-temple-497099/) | Djovan | `djovan-zen-temple-497099.mp3` |
| [First Light Temple](https://pixabay.com/music/world-first-light-temple-575223/) | Djovan | `djovan-first-light-temple-575223.mp3` |

## Come si mettono

1. Apri il link del brano e premi **Download** (gratis; Pixabay a volte chiede
   di entrare con un account, anche quello gratis).
2. Sposta il file scaricato **in questa cartella** (`musica/giardino/`). Il nome può
   restare quello che ha.
3. Dalla cartella del Pomodoro, rilancia:
   ```bash
   musica/elenca.sh
   ```
   Riscrive `musica/brani.js`, l'elenco che la pagina del bioma legge (una
   pagina aperta da file non sa leggere una cartella da sola), e misura il
   volume di ogni brano. Serve `ffmpeg` (`brew install ffmpeg`); senza, ogni
   brano vale -14 LUFS e il volume può venire sbagliato.

Non serve riavviare niente: alla pausa dopo, il giardino pesca uno di questi brani.

## Come suonano

- a ogni pausa il bioma ne sceglie **uno a caso** fra quelli di questa cartella;
- tutti vengono portati allo stesso volume (-31 LUFS), **sotto i suoni** del
  bioma: la musica accompagna, non copre;
- li suona all'**85% della velocità**, un po' più gravi e più lenti;
- sfumano negli ultimi 2,5 secondi della pausa, e si zittiscono se il bioma
  sparisce.

## Metterne altri, o toglierli

Qualunque mp3, m4a, wav, ogg o aac messo qui entra nel giro, anche brani tuoi.
Per togliere un brano lo cancelli o lo sposti, e rilanci `musica/elenca.sh`.
Se la cartella resta vuota, il bioma suona lo stesso, con i suoi suoni e senza
musica (o con un brano sciolto in `musica/`, se ce ne sono).
