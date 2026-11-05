#!/bin/zsh
# Impacchetta ogni fondali/<bioma>-gemini.jpg in fondali/<bioma>.js, che la scena
# include con <script>. Serve perché una pagina aperta da file non può leggere i
# pixel di un'immagine letta da file (SecurityError), mentre di un data: sì.
cd "${0:A:h}"
for f in *-gemini.jpg; do
  n=${f%-gemini.jpg}
  print -n "FONDALE = 'data:image/jpeg;base64," > $n.js
  base64 -i $f | tr -d '\n' >> $n.js
  print "';" >> $n.js
  print "$n.js"
done
