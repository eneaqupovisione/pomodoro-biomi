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

**I brani scelti per ogni bioma**, coi link alle pagine di Pixabay, il nome del file
che scarichi e come metterlo, stanno nella cartella del bioma:

| bioma | l'aria | |
|---|---|---|
| stagno | calmo, liquido, lento: koto, kalimba | [`stagno/LEGGIMI.md`](stagno/LEGGIMI.md) |
| giardino | raccolto, sacro, un po' misterioso: shakuhachi, tempio | [`giardino/LEGGIMI.md`](giardino/LEGGIMI.md) |
| pioggia | malinconia urbana, notturno: piano jazz, Rhodes | [`pioggia/LEGGIMI.md`](pioggia/LEGGIMI.md) |
| mare | ampio, arioso: piano, chitarra con molto riverbero | [`mare/LEGGIMI.md`](mare/LEGGIMI.md) |

Pixabay non si scarica da riga di comando: si scarica dal browser, poi si sposta
il file nella cartella del bioma.
