// Quello che ogni bioma ha in comune: la query, il sole, il timer, gli inviti,
// la musica e quando l'audio si spegne. Un bioma è una pagina in
// scene/ con #timer e #invito, che include questo file e poi disegna; i suoi
// suoni li costruisce in fondo(), chiamata quando parte l'audio.
//
// La apre Pomodoro.app con ?fine=<ms epoch>&suono=1|0[&musica=<file in ../musica>]
// [&lat=…&lon=…] e i fatti della giornata, che possono mancare: uscite=N (pause
// tolte coi dieci tocchi oggi). Nel browser si può aggiungere &ora=22:30 per forzare
// l'ora del giorno. Ogni .html di scene/ è un bioma sceglibile nel Pomodoro.
// L'app scrive i tocchi per uscire appena sopra la fascia dell'invito: lì
// niente di importante.
//
// I suoni si fermano del tutto quando la schermata del bioma sparisce. Chiudere la
// finestra non basta: la WKWebView chiusa resta viva e continua a suonare. Così lo fa
// la pagina: quando non si vede più si zittisce, se torna riprende, e a fine pausa
// sfuma e spegne.
const Q = new URLSearchParams(location.search);
const FINE = Number(Q.get('fine')) || Date.now() + 300000;
const SUONO = Q.get('suono') !== '0';
const ORA = Q.get('ora');
const numero = k => Q.has(k) && Q.get(k) !== '' && !isNaN(Q.get(k)) ? Number(Q.get(k)) : null;
const OGGI = { uscite: numero('uscite') };
// Dove sta il sole: impostazioni.json, luogo: {lat, lon}; senza, Roma
const LAT = numero('lat') ?? 41.9, LON = numero('lon') ?? 12.5;

const sm = (a, b, x) => { const q = Math.min(1, Math.max(0, (x - a) / (b - a))); return q * q * (3 - 2 * q); };

// ---------- Il sole: l'altezza vera sopra LAT, LON, così di notte è notte ----------
function sole(date) {
  const lat = LAT * Math.PI / 180, lon = LON;
  const n = date.getTime() / 86400000 + 2440587.5 - 2451545.0;
  const g = (357.529 + 0.98560028 * n) * Math.PI / 180, q = 280.459 + 0.98564736 * n;
  const L = (q + 1.915 * Math.sin(g) + 0.020 * Math.sin(2 * g)) * Math.PI / 180;
  const e = (23.439 - 0.00000036 * n) * Math.PI / 180;
  const ra = Math.atan2(Math.cos(e) * Math.sin(L), Math.cos(L)), dec = Math.asin(Math.sin(e) * Math.sin(L));
  const gmst = ((18.697374558 + 24.06570982441908 * n) % 24 + 24) % 24;
  const ha = (gmst * 15 + lon) * Math.PI / 180 - ra;
  return Math.asin(Math.sin(lat) * Math.sin(dec) + Math.cos(lat) * Math.cos(dec) * Math.cos(ha)) * 180 / Math.PI;
}
function adesso() {
  if (!ORA) return new Date();
  const [h, m] = ORA.split(':').map(Number), t = new Date(); t.setHours(h, m || 0, 0, 0); return t;
}
let giorno = 1, tramonto = 0;          // 1 pieno giorno, 0 notte; tramonto: quanto è arancio
function luce() {
  const alt = sole(adesso());
  giorno = sm(-7, 5, alt);
  tramonto = Math.max(0, 1 - Math.abs(alt - 1) / 7);
}
luce(); setInterval(luce, 30000);
const MESE = adesso().getMonth();

// ---------- L'audio ----------
let AC = null, master = null, finito = false, fondo = () => {};
function audio() {
  if (AC || !SUONO || finito) return;
  try {
    AC = new (window.AudioContext || window.webkitAudioContext)();
    master = AC.createGain(); master.gain.value = 0.9; master.connect(AC.destination);
    fondo();   // la campana d'inizio (campana()) resta qui, ma nessun bioma la suona più
    if (document.hidden) AC.suspend();
  } catch (e) { AC = null; }
}
function inviluppo(g, t, picco, attacco, coda) { g.gain.setValueAtTime(0.0001, t); g.gain.linearRampToValueAtTime(picco, t + attacco); g.gain.exponentialRampToValueAtTime(0.0001, t + attacco + coda); }
function campana() {          // l'inizio della pausa: una volta, anche se l'app ricarica la scena
  if (!AC) return;
  try { if (localStorage.getItem('campana') === String(FINE)) return; localStorage.setItem('campana', String(FINE)); } catch (e) {}
  const t = AC.currentTime + 0.1;
  for (const [f, v] of [[528, .07], [792, .04], [1056, .02]]) { const o = AC.createOscillator(), g = AC.createGain(); o.frequency.value = f; inviluppo(g, t, v, 0.01, 3); o.connect(g); g.connect(master); o.start(t); o.stop(t + 3.2); }
}
function rumore(secondi, passo) {   // rumore marrone in un buffer che si ripete: acqua, pioggia, vento
  // Senza cucitura, la fine non combacia con l'inizio e a ogni giro si sente un colpo:
  // si genera mezzo secondo in più e lo si sfuma nell'inizio.
  const n = Math.round(AC.sampleRate * secondi), M = Math.min(Math.round(AC.sampleRate * .5), n >> 1);
  const tmp = new Float32Array(n + M), buf = AC.createBuffer(1, n, AC.sampleRate), ch = buf.getChannelData(0);
  let last = 0; for (let i = 0; i < n + M; i++) { last = (last + passo * (Math.random() * 2 - 1)) / (1 + passo); tmp[i] = last * 3.5; }
  for (let i = 0; i < n; i++) ch[i] = tmp[i];
  for (let i = 0; i < M; i++) { const w = i / M; ch[i] = tmp[i] * w + tmp[n + i] * (1 - w); }
  const src = AC.createBufferSource(); src.buffer = buf; src.loop = true; return src;
}

// La musica: un brano, piano, che entra in quattro secondi. Prima quelli del bioma, in
// musica/<bioma>/ (elencati in musica/brani.js da musica/elenca.sh: una pagina aperta da file non
// può leggere una cartella); se non ce ne sono, quello che l'app ha pescato dai file sciolti di musica/
const VOL_MUSICA = 0.3, BIOMA = decodeURIComponent(location.pathname.split('/').pop().replace(/\.html$/, ''));
const DEL_BIOMA = typeof BRANI !== 'undefined' && BRANI[BIOMA] || [];
const SCELTO = DEL_BIOMA[Math.floor(Math.random() * DEL_BIOMA.length)];   // [file, LUFS]
const BRANO = SCELTO ? [BIOMA, SCELTO[0]] : Q.get('musica') ? [Q.get('musica')] : null;
// i brani arrivano di solito fra -11 e -25 LUFS, i suoni dei biomi fra -22 e -30: ogni brano del
// bioma va a -31, sotto i suoni; quello pescato dall'app, che non è misurato, resta a 0,3
const VOL_BRANO = SCELTO ? Math.min(1, Math.pow(10, (-31 - SCELTO[1]) / 20)) : VOL_MUSICA;
// un po' più lenta: all'85%, come un nastro rallentato, quindi anche un po' più grave
// (tenere l'altezza vorrebbe dire stirare il suono, e un piano stirato si sente)
const LENTO = .85;
let brano = null, volume = 0, sfumaVerso = VOL_BRANO, respiro = 1;   // respiro: il bioma può far ondeggiare la musica
if (BRANO && SUONO) {
  brano = new Audio('../musica/' + BRANO.map(encodeURIComponent).join('/')); brano.loop = true; brano.volume = 0;
  brano.preservesPitch = brano.webkitPreservesPitch = false; brano.playbackRate = brano.defaultPlaybackRate = LENTO;
  brano.play().catch(() => addEventListener('pointerdown', () => !finito && brano.play(), { once: true }));
  setInterval(() => { if (!brano) return; volume += Math.sign(sfumaVerso - volume) * Math.min(Math.abs(sfumaVerso - volume), VOL_BRANO / 40); brano.volume = volume * respiro; }, 100);
}

function zitto(si) {          // la scena sparisce o torna
  if (finito) return;
  if (si) { if (AC) AC.suspend(); if (brano) brano.pause(); }
  else { if (AC) AC.resume(); if (brano) brano.play().catch(() => {}); }
}
function spegni() {           // per sempre: niente più suoni da questa pagina
  finito = true;
  if (AC) { AC.close(); AC = null; }
  if (brano) { brano.pause(); brano.removeAttribute('src'); brano.load(); brano = null; }
}
let sfumando = false;
function sfuma(secondi) {
  if (sfumando) return; sfumando = true;
  if (master) master.gain.setTargetAtTime(0.0001, AC.currentTime, secondi / 5);
  sfumaVerso = 0;
  setTimeout(spegni, secondi * 1000);
}
document.addEventListener('visibilitychange', () => zitto(document.hidden));
addEventListener('pagehide', spegni);

// ---------- Il timer e gli inviti: vengono dalla ricerca sugli occhi (occhi.md) ----------
const inviti = ["cerca la cosa più lontana che vedi", "qualche battito di ciglia lento, fino in fondo", "alzati: collo e spalle aspettavano",
  "se c'è una finestra, guarda il cielo", "il telefono può aspettare: è più vicino agli occhi dello schermo", "un sorso d'acqua, e guarda fuori",
  "lascia vagare lo sguardo, senza fissare niente", "quando torni: lo schermo è luminoso quanto la stanza?"];
let ii = 0;
const elInvito = document.getElementById('invito'), elTimer = document.getElementById('timer');
function cambiaInvito() {       // uno su due: chiudi gli occhi, stringi, riapri
  elInvito.style.opacity = 0;
  setTimeout(() => { elInvito.textContent = ii % 2 ? inviti[(ii >> 1) % inviti.length] : "chiudi gli occhi, stringi, riapri"; ii++; elInvito.style.opacity = 1; }, 800);
}
function orologio() {
  const ms = FINE - Date.now(), resto = Math.max(0, Math.ceil(ms / 1000));
  elTimer.textContent = Math.floor(resto / 60) + ":" + String(resto % 60).padStart(2, '0');
  if (ms < 2500) sfuma(2.5);     // a finestra chiusa deve essere già silenzio
}
cambiaInvito(); setInterval(cambiaInvito, 9000);
orologio(); setInterval(orologio, 250);

// ---------- Il fondale: un'immagine di fondali/ ridotta a pixel veri ----------
// Le immagini di Gemini sono pixel art finta: quadretti di circa 3 pixel,
// sbavati dal JPEG. La si ritaglia per coprire la tela (W×H), la si rimpicciolisce
// facendo la media, e i colori si riducono a una tavolozza di `colori` (k-means),
// tranne gli accenti; le luci piccole (pixel caldi e chiari) si salvano prima della media.
// `luce` è quanto deve essere chiaro (r) e caldo (r - b) un pixel per contare come luce.
// Restituisce i pixel in RGB, tre byte ciascuno.
function caricaFondale(src, W, H, colori = 40, luce = { r: 140, rb: 45 }) {
  return new Promise((ok, no) => {
    const im = new Image();
    im.onload = () => { try {
      const c = document.createElement('canvas'); c.width = W; c.height = H;
      const g = c.getContext('2d'); g.imageSmoothingEnabled = true; g.imageSmoothingQuality = 'high';
      const s = Math.max(W / im.width, H / im.height), sw = W / s, sh = H / s;
      g.drawImage(im, (im.width - sw) / 2, (im.height - sh) / 2, sw, sh, 0, 0, W, H);
      const src4 = g.getImageData(0, 0, W, H).data, n = W * H, px = new Uint8ClampedArray(n * 3);
      for (let i = 0; i < n; i++) { px[i * 3] = src4[i * 4]; px[i * 3 + 1] = src4[i * 4 + 1]; px[i * 3 + 2] = src4[i * 4 + 2]; }
      // le luci (finestre, lanterne) sono un pixel di Gemini: la media le spegnerebbe. Se in un
      // quadretto c'è un pixel caldo e chiaro, il pixel ridotto prende il suo colore.
      const gc = document.createElement('canvas'); gc.width = im.width; gc.height = im.height;
      const gg = gc.getContext('2d'); gg.drawImage(im, 0, 0); const big = gg.getImageData(0, 0, im.width, im.height).data;
      const calore = new Float32Array(n), ox = (im.width - sw) / 2, oy = (im.height - sh) / 2;
      for (let y = 0; y < im.height; y++) for (let x = 0; x < im.width; x++) {
        const j = (y * im.width + x) * 4, r = big[j], gr = big[j + 1], b = big[j + 2], c = (r - b) + (r + gr) * .25;
        if (r < luce.r || r - b < luce.rb || gr < luce.r * .6) continue;
        const tx = Math.floor((x - ox) * s), ty = Math.floor((y - oy) * s); if (tx < 0 || ty < 0 || tx >= W || ty >= H) continue;
        const i = ty * W + tx; if (c > calore[i]) { calore[i] = c; px[i * 3] = r; px[i * 3 + 1] = gr; px[i * 3 + 2] = b; }
      }
      // la tavolozza: k-means, partendo da pixel presi a intervalli regolari
      const K = colori, cen = new Float32Array(K * 3), chi = new Uint8Array(n);
      for (let k = 0; k < K; k++) { const i = Math.floor((k + .5) / K * n) * 3; cen[k * 3] = px[i]; cen[k * 3 + 1] = px[i + 1]; cen[k * 3 + 2] = px[i + 2]; }
      for (let giro = 0; giro < 8; giro++) {
        const som = new Float32Array(K * 4);
        for (let i = 0; i < n; i++) {
          let best = 0, bd = 1e9; const r = px[i * 3], gg = px[i * 3 + 1], b = px[i * 3 + 2];
          for (let k = 0; k < K; k++) { const dr = r - cen[k * 3], dg = gg - cen[k * 3 + 1], db = b - cen[k * 3 + 2], dd = dr * dr * 2 + dg * dg * 3 + db * db; if (dd < bd) { bd = dd; best = k; } }
          chi[i] = best; som[best * 4] += r; som[best * 4 + 1] += gg; som[best * 4 + 2] += b; som[best * 4 + 3]++;
        }
        for (let k = 0; k < K; k++) if (som[k * 4 + 3]) for (let j = 0; j < 3; j++) cen[k * 3 + j] = som[k * 4 + j] / som[k * 4 + 3];
      }
      // un pixel lontano da tutti i colori della tavolozza è un accento (una luce, un fiore): resta com'è
      for (let i = 0; i < n; i++) {
        const k = chi[i], dr = px[i * 3] - cen[k * 3], dg = px[i * 3 + 1] - cen[k * 3 + 1], db = px[i * 3 + 2] - cen[k * 3 + 2];
        if (dr * dr + dg * dg + db * db < 1600) for (let j = 0; j < 3; j++) px[i * 3 + j] = cen[k * 3 + j];
      }
      ok(px);
    } catch (e) { no(e); } };
    im.onerror = no; im.src = src;
  });
}

// ---------- I suoni registrati: suoni/<bioma>.js, con SUONI = { nome: 'data:…' } ----------
// Registrazioni vere (CC0, da Freesound: suoni/LEGGIMI.md), perché la pioggia fatta col
// codice sembrava di cartone. Come per i fondali, una pagina aperta da file legge un
// data: e non un file.
const registrati = {};
function suono(nome) {          // la registrazione decodificata, una volta sola
  if (!AC || typeof SUONI === 'undefined' || !SUONI[nome]) return Promise.reject(nome);
  return registrati[nome] || (registrati[nome] = fetch(SUONI[nome]).then(r => r.arrayBuffer()).then(b => AC.decodeAudioData(b)));
}
function ciclo(buf, sfuma = 1.5) {   // un loop che non si sente: la fine sfuma nell'inizio
  const M = Math.min(Math.round(buf.sampleRate * sfuma), buf.length >> 2), n = buf.length - M;
  const out = AC.createBuffer(buf.numberOfChannels, n, buf.sampleRate);
  for (let c = 0; c < buf.numberOfChannels; c++) {
    const a = buf.getChannelData(c), o = out.getChannelData(c);
    for (let i = 0; i < n; i++) o[i] = a[i];
    for (let i = 0; i < M; i++) { const w = Math.sin(i / M * Math.PI / 2); o[i] = a[i] * w + a[n + i] * Math.cos(i / M * Math.PI / 2); }
  }
  const src = AC.createBufferSource(); src.buffer = out; src.loop = true; return src;
}
function colpo(buf, inizio, durata, volume = 1, pan = 0, uscita = master) {   // un pezzo della registrazione, una volta
  if (!AC || !buf) return null; const t = AC.currentTime, s = AC.createBufferSource(), g = AC.createGain(), p = AC.createStereoPanner();
  s.buffer = buf; p.pan.value = pan; const f = Math.min(.08, durata / 4);
  g.gain.setValueAtTime(0, t); g.gain.linearRampToValueAtTime(volume, t + f); g.gain.setValueAtTime(volume, t + durata - f); g.gain.linearRampToValueAtTime(0, t + durata);
  s.connect(g); g.connect(p); p.connect(uscita); s.start(t, inizio, durata); return g;
}
