#!/bin/zsh
# Rifà brani.js: i brani di ogni musica/<bioma>/ col loro volume, che la pagina del bioma pesca a caso.
# Va rilanciato quando si aggiunge o si toglie un brano (una pagina aperta da file non può
# leggere una cartella da sola). I file sciolti in musica/ li pesca l'app, per i biomi senza i loro.
cd "${0:A:h}"
print "BRANI = {" > brani.js
for d in */(N/); do
  d=${d%/}; print -n "  '$d': [" >> brani.js
  for f in $d/*.(mp3|m4a|wav|ogg|aac)(N); do
    # il volume del brano (LUFS integrati): la pagina lo porta a un livello solo, sotto i suoni
    local I=$(ffmpeg -hide_banner -nostats -i $f -af ebur128 -f null - 2>&1 | awk '/^ +I:/ {print $2}' | tail -1)
    print -n "['${${f:t}//\'/\\\'}', ${I:--14}], " >> brani.js
  done
  print "]," >> brani.js
done
print "};" >> brani.js
cat brani.js
