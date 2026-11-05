#!/bin/zsh
# Taglia le registrazioni di originali/<bioma>/ (e originali/comuni/) e le impacchetta in <bioma>.js
# (SUONI = { nome: 'data:audio/mp4;base64,…' }), che la scena include con <script>.
# I tratti sono stati scelti misurando il volume secondo per secondo.
cd "${0:A:h}"
T=$(mktemp -d)
# o <file>: dove sta una registrazione, in qualunque sottocartella di originali/
o() { local f=(originali/*/$1(N)); print -r -- ${f[1]:?manca $1} }
taglia() { ffmpeg -hide_banner -loglevel error -y -ss $3 -t $4 -i $(o $2) -ac 2 -ar 44100 -c:a aac -b:a 112k $T/$1.m4a }
# come taglia, ma porta il volume a un livello udibile (per le registrazioni fatte molto piano)
alza() { ffmpeg -hide_banner -loglevel error -y -ss $3 -t $4 -i $(o $2) -af loudnorm=I=-24:TP=-3 -ac 2 -ar 44100 -c:a aac -b:a 112k $T/$1.m4a }
pacchetto() {   # pacchetto <bioma> <nome>...
  local out=$1.js; shift
  print "SUONI = {" > $out
  for n in $@; do print -n "  $n: 'data:audio/mp4;base64," >> $out; base64 -i $T/$n.m4a | tr -d '\n' >> $out; print "'," >> $out; done
  print "};" >> $out; print "$out $(du -h $out | cut -f1)"
}
# pioggia: il sottofondo regolare (tutto il minuto è a -19 dB), il tuono (colpo al secondo 26,
# poi il brontolio), il dito sul vetro (stridii di mezzo secondo, elencati in pioggia.html)
# la pioggia: non più contro il vetro, che non era rilassante (bastipictures), ma una pioggia calma e uniforme (hoshisato, CC0), registrata
# piano e alzata (è pioggia: il suo fruscio è il suono stesso), senza il rombo basso
# e senza i suoi uccelli («non voglio sentire uccelli o animali vari»): quattro cinguettii fra 2,1 e
# 3,2 kHz, tolti spegnendo quella banda solo nei loro istanti; la pioggia intorno non cambia
U="between(t,10.1,11.5)+between(t,16.2,17.2)+between(t,18.3,19)+between(t,23.8,24.8)"
ffmpeg -hide_banner -loglevel error -y -i $(o pioggia-calma_hoshisato-853565.mp3) -af "highpass=f=120,bandreject=f=2650:width_type=h:w=1300:enable='$U',bandreject=f=2650:width_type=h:w=1300:enable='$U',bandreject=f=2650:width_type=h:w=1300:enable='$U',loudnorm=I=-24:TP=-3" -ac 2 -ar 44100 -c:a aac -b:a 96k $T/pioggia.m4a
# le fusa del gatto accarezzato (arseniiv, CC0): la parte calda, senza il fruscio acuto
ffmpeg -hide_banner -loglevel error -y -ss 2.5 -t 14 -i $(o fusa-contenta_arseniiv-707237.mp3) -af highpass=f=60,lowpass=f=1800,loudnorm=I=-24:TP=-3 -ac 1 -ar 44100 -c:a aac -b:a 64k $T/fusa.m4a
taglia tuono    tuono-lontano_rutgermuller-158692.mp3 23 50
taglia vetro    dito-sul-vetro_mickdow-320912.mp3 0 46.5
# il traffico ovattato e il crepitio del vinile: il vinile di kyles (CC0), senza il rombo
# basso, solo il crepitio; il traffico da un balcone di rionka (CC0), dal secondo 12 (prima ci sono
# bip e un tram), passato da un passa-basso stretto: la città sentita da dietro il vetro
ffmpeg -hide_banner -loglevel error -y -ss 10 -t 24 -i $(o vinile_kyles-637931.mp3) -af highpass=f=900,highpass=f=900,loudnorm=I=-40:TP=-9 -ac 2 -ar 44100 -c:a aac -b:a 64k $T/vinile.m4a
ffmpeg -hide_banner -loglevel error -y -ss 12 -t 20 -i $(o traffico-balcone_rionka-475867.mp3) -af lowpass=f=420,lowpass=f=420,loudnorm=I=-34:TP=-8 -ac 1 -ar 44100 -c:a aac -b:a 64k $T/traffico.m4a
pacchetto pioggia pioggia tuono vetro vinile traffico fusa
# giardino: le foglie nel vento, due registrazioni da mescolare col vento
taglia foglie   foglie-nel-vento_lunchmoney-378725.mp3 2.5 33.5
taglia foglie2  foglie_kinoton-347557.mp3 0.3 18.4
# la nota di carillon (thomasjaunism, CC0): un fa acuto, suonato dalla scena a altezze diverse.
# Nello stagno le lucciole, nel giardino la «celesta» degli onibi
ffmpeg -hide_banner -loglevel error -y -t 2.35 -i $(o carillon-nota_thomasjaunism-218459.mp3) -af afade=t=out:st=1.8:d=0.55,loudnorm=I=-20:TP=-3 -ac 1 -ar 44100 -c:a aac -b:a 96k $T/carillon.m4a
pacchetto giardino foglie foglie2 carillon
# mare: «Calm ocean waves», un'onda ogni 10-15 s con creste chiare (la scena le trova e
# ci fa arrivare l'onda disegnata); i gabbiani lontani, registrati molto piano
taglia mare     onde-calme_samsterbirdies-578524.mp3 2 120
# i gabbiani: la serie di versi chiari fra il secondo 3 e il 21 di «A quiet seaside» (il primo
# file, «Seagulls distant», era un fondo uniforme: i versi non si sentivano), senza il rumore basso
ffmpeg -hide_banner -loglevel error -y -ss 3 -t 18 -i $(o gabbiani-riva_selcukartut-546565.mp3) -af highpass=f=350,loudnorm=I=-20:TP=-2 -ac 2 -ar 44100 -c:a aac -b:a 112k $T/gabbiani.m4a
pacchetto mare mare gabbiani
# stagno: di giorno lo stagno d'autunno (loopabile), di notte il lago; tutti e due
# registrati piano, quindi alzati. La rana: i tre gracidii fra il secondo 6,5 e il 19,5
ffmpeg -hide_banner -loglevel error -y -ss 0 -t 14.8 -i $(o stagno-autunno_mjeno-405135.mp3) -af loudnorm=I=-26:TP=-3 -ac 2 -ar 44100 -c:a aac -b:a 112k $T/stagno.m4a
ffmpeg -hide_banner -loglevel error -y -ss 0.4 -t 43.4 -i $(o lago-di-notte_timgormly-148318.mp3) -af loudnorm=I=-26:TP=-3 -ac 2 -ar 44100 -c:a aac -b:a 112k $T/lago.m4a
ffmpeg -hide_banner -loglevel error -y -ss 6.5 -t 13 -i $(o rana_sandermotions-278868.mp3) -af highpass=f=150,loudnorm=I=-22:TP=-2 -ac 2 -ar 44100 -c:a aac -b:a 112k $T/rana.m4a
# (stagno e lago tolti dalla scena: alzati, portavano un fruscio; restano tagliati qui per riprovarli)
# Il sottofondo di uno stagno: qualche uccellino, qualche gracidio, i grilli. Di giorno lo stagno di maphill: rane, uccelli e insetti, già ripulito
# e registrato forte (-24 LUFS), quindi abbassato e non alzato: il fruscio non torna su.
ffmpeg -hide_banner -loglevel error -y -ss 0.3 -t 62.7 -i $(o stagno-rane-uccelli_maphill-364300.mp3) -af highpass=f=120,loudnorm=I=-30:TP=-4 -ac 2 -ar 44100 -c:a aac -b:a 112k $T/giorno.m4a
# di notte la palude di RealSquink (rane, rospi, fischi), molto forte (-18,5 LUFS): abbassata
ffmpeg -hide_banner -loglevel error -y -ss 76 -t 60 -i $(o palude-notte_realsquink-826445.mp3) -af highpass=f=150,loudnorm=I=-32:TP=-4 -ac 2 -ar 44100 -c:a aac -b:a 112k $T/notte.m4a
# versi in fila: versi <nome> <file> <passa-alto> <inizio:durata>... → ogni verso sfuma dentro e fuori
# (0,35 s e 0,5 s: nessuno parte di colpo), 0,3 s di silenzio fra uno e l'altro, mono (la scena lo
# mette a destra o a sinistra). Gli inizi e le durate stanno in stagno.html (VERSI)
# FI e FO cambiano le sfumature, LP aggiunge un passa-basso, LN il volume (per i colpi brevi)
versi() {
  local nome=$1 file=$2 hp=$3 F="" L="" i=0 fi=${FI:-0.35} fo=${FO:-0.5} lp=${LP:+,lowpass=f=$LP}; shift 3
  for c in $@; do local s=${c%:*} d=${c#*:}; F+="[0:a]atrim=$s:$(( s + d )),asetpts=PTS-STARTPTS,afade=t=in:d=$fi,afade=t=out:st=$(( d - fo )):d=$fo,apad=pad_dur=0.3[c$i];"; L+="[c$i]"; i=$(( i + 1 )); done
  ffmpeg -hide_banner -loglevel error -y -i $(o $file) -filter_complex "${F}${L}concat=n=$i:v=0:a=1,highpass=f=$hp,highpass=f=$hp$lp,loudnorm=I=${LN:--24}:TP=-3" -ac 1 -ar 44100 -c:a aac -b:a 96k $T/$nome.m4a
}
# gli uccellini, nostri: il pettirosso e il merlo di Sacha.Julien (sud della Francia), i versi
# trovati misurando gli acuti ogni decimo di secondo (12 dB sopra il fondo). Solo la prima parte
# delle due registrazioni: dopo cambia presa e arrivano colpi bassi
versi pettirosso pettirosso_sachajulien-725331.mp3 1500 2.85:3.70 8.95:3.40 14.65:3.50 20.65:4.30 27.15:4.70 34.45:3.70 39.85:4.10 46.35:4.00 51.85:4.40 68.05:4.00
versi merlo merlo_sachajulien-725332.mp3 1100 0.95:3.20 6.75:3.30 11.65:3.90 17.65:2.60 22.25:3.60 30.05:4.10 36.75:3.50 43.05:4.10 48.95:2.70
# (non più usati: gli 8 canti della palude di MarleneAyni finivano in un trillo che partiva e si
# fermava di colpo: sembrava una libellula)
# gli uccellini: gli 8 canti della palude di MarleneAyni (trovati misurando gli acuti ogni quarto di
# secondo: 20 dB sopra il fondo), in fila con 0,3 s di silenzio fra uno e l'altro; senza i bassi.
# Gli inizi e le durate in stagno.html (CANTI)
C=(5.05:1.4 19.85:1.35 37.05:1.4 63.85:1.45 90.35:1.35 98.15:1.55 111.05:1.35 137.05:1.65)
F=""; L=""; i=0
for c in $C; do s=${c%:*}; d=${c#*:}; F+="[0:a]atrim=$s:$(( s + d )),asetpts=PTS-STARTPTS,afade=t=in:d=0.08,afade=t=out:st=$(( d - 0.25 )):d=0.25,apad=pad_dur=0.3[c$i];"; L+="[c$i]"; i=$(( i + 1 )); done
ffmpeg -hide_banner -loglevel error -y -i $(o palude_marleneayni-580325.mp3) -filter_complex "${F}${L}concat=n=$i:v=0:a=1,highpass=f=1400,highpass=f=1400,loudnorm=I=-24:TP=-3" -ac 2 -ar 44100 -c:a aac -b:a 112k $T/uccelli.m4a
# la rana: i 5 «gunk» della rana verde nella palude di MarleneAyni (25 dB sopra il fondo, trovati
# misurando i bassi ogni 50 ms), con un attacco vero e una coda sfumata. La rana di Sandermotions
# (sopra) è spenta: per sentirla andava alzata di 35 dB, e i tratti suonati erano soprattutto il suo
# fruscio: un suono che si accende, dura pochissimo e sparisce, come un ronzio
F=""; L=""; i=0
for s in 7.06 40.11 63.31 84.86 114.16; do F+="[0:a]atrim=$s:$(( s + 0.5 )),asetpts=PTS-STARTPTS,afade=t=in:d=0.02,afade=t=out:st=0.25:d=0.25,apad=pad_dur=0.3[c$i];"; L+="[c$i]"; i=$(( i + 1 )); done
ffmpeg -hide_banner -loglevel error -y -i $(o palude_marleneayni-580325.mp3) -filter_complex "${F}${L}concat=n=$i:v=0:a=1,highpass=f=150,lowpass=f=2600,loudnorm=I=-22:TP=-2" -ac 1 -ar 44100 -c:a aac -b:a 96k $T/rana.m4a
# l'acqua: una voce per chi la tocca, più acquosa del plic fatto col codice. Il dito sono 10 pezzi
# di una mano che si muove piano nell'acqua (Daen23), la rana che atterra i 3 schizzi di N-RAZM
# ammorbiditi, le foglie la goccia fine di qubodup
FI=0.03 FO=0.3 versi tocco acqua-mano_daen23-431627.mp3 120 4.35:0.6 7.40:0.6 8.35:0.6 9.20:0.6 12.70:0.6 13.60:0.6 18.10:0.6 19.00:0.6 23.10:0.6 24.20:0.6
FI=0.01 FO=0.3 LP=4500 versi tonfo schizzi-piccoli_nrazm-390391.mp3 120 2.42:0.5 8.22:0.5 15.38:0.5
FI=0.005 FO=0.15 LN=-20 versi goccia goccia-fine_qubodup-792927.mp3 200 0:0.39
# le raganelle: il «ribbit» dei film (Pacific Tree Frogs di CVLTIV8R), un coro fitto e basso, un giro
# sotto il sottofondo, al posto dei «gunk» della rana verde
ffmpeg -hide_banner -loglevel error -y -ss 0.3 -t 50 -i $(o raganelle_cvltiv8r-852657.mp3) -af highpass=f=500,loudnorm=I=-34:TP=-6 -ac 1 -ar 44100 -c:a aac -b:a 80k $T/raganelle.m4a
pacchetto stagno rana giorno notte pettirosso merlo tocco tonfo goccia raganelle carillon
rm -r $T
