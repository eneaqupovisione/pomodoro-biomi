# La musica dei biomi

Il repository **non contiene musica**: i brani hanno licenze che non permettono di
ridistribuirli così come sono. Li scarichi tu, e li metti qui. Senza brani i biomi
funzionano lo stesso, con i loro suoni.

## Dove vanno

- `musica/<bioma>/` (per esempio `musica/stagno/`): i brani di quel bioma. A ogni
  pausa la pagina del bioma ne pesca uno a caso.
- `musica/` (file sciolti): l'app ne pesca uno a caso per i biomi che non hanno
  brani loro.

Formati: mp3, m4a, wav, ogg, aac.

**Dopo aver aggiunto o tolto un brano** di una cartella `musica/<bioma>/` si
rilancia:

```bash
musica/elenca.sh
```

Riscrive `musica/brani.js` (una pagina aperta da file non può leggere una
cartella da sola) e misura il volume di ogni brano (LUFS integrati, con `ffmpeg`):
la pagina li porta tutti a -31 LUFS, sotto i suoni del bioma, e li suona all'85%
della velocità, un po' più gravi. Senza `ffmpeg` (`brew install ffmpeg`) ogni brano
vale -14 LUFS.

I file sciolti non serve elencarli: li vede l'app.

## Cosa cercare

Lento e semplice, senza batteria né voce, lungo. Fonti con licenze che permettono
l'uso personale: [Pixabay Music](https://pixabay.com/music/),
[Free Music Archive](https://freemusicarchive.org),
[Incompetech](https://incompetech.com).

Un punto di partenza, bioma per bioma (titoli su Pixabay Music, da cercare per nome):

| bioma | l'aria | brani |
|---|---|---|
| stagno | calmo, liquido, lento: koto, kalimba | *In the place far away* (harumachimusic), *Bamboo Forest 285Hz* (Dominique Garnier), *Japanese Aikoto Instrumental 7* (koto-japan-soundtrack) |
| giardino | raccolto, sacro, un po' misterioso: shakuhachi, tempio | *Zen Temple*, *First Light Temple* (Djovan) |
| pioggia | malinconia urbana, notturno: piano jazz, Rhodes | *New York Jazz Midnight* (MarkMusicStudio), *Slow Music - Slow* (AndriiH) |
| mare | ampio, arioso: piano, chitarra con molto riverbero | *Slow* (Luceris), *Minimal Piano* (AtlasAudio) |

Pixabay non si scarica da riga di comando: si scarica dal browser, poi si sposta
il file nella cartella del bioma.
