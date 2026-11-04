// node cdp.mjs <url> <secondi> <espressione> [foto.png]: apre la pagina in Chrome senza schermo
// (nessuna finestra), aspetta in tempo vero, valuta l'espressione; con foto.png fa anche la foto.
import { spawn } from 'node:child_process';
const [url, sec, expr] = process.argv.slice(2);
const C = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ch = spawn(C, ['--headless=new', '--disable-gpu', '--use-mock-keychain', '--password-store=basic', '--no-first-run',
  '--user-data-dir=' + (process.env.PROFILO || '/tmp/pomodoro-chrome'), '--autoplay-policy=no-user-gesture-required', '--remote-debugging-port=9333', '--window-size=1280,832', '--hide-scrollbars', url], { stdio: 'ignore' });
const dorme = ms => new Promise(r => setTimeout(r, ms));
let ws;
for (let i = 0; i < 40 && !ws; i++) { await dorme(250); try { const l = await (await fetch('http://127.0.0.1:9333/json')).json(); const p = l.find(x => x.type === 'page'); if (p) ws = p.webSocketDebuggerUrl; } catch {} }
await dorme(sec * 1000);
const s = new WebSocket(ws); await new Promise(r => s.onopen = r);
s.send(JSON.stringify({ id: 1, method: 'Runtime.evaluate', params: { expression: expr, awaitPromise: true, returnByValue: true } }));
const r = await new Promise(ok => s.onmessage = m => { const d = JSON.parse(m.data); if (d.id === 1) ok(d); });
console.log(JSON.stringify(r.result.result.value ?? r.result));
if (process.argv[5]) {
  s.send(JSON.stringify({ id: 2, method: 'Page.captureScreenshot', params: { format: 'png' } }));
  const f = await new Promise(ok => s.onmessage = m => { const d = JSON.parse(m.data); if (d.id === 2) ok(d); });
  (await import('node:fs')).writeFileSync(process.argv[5], Buffer.from(f.result.data, 'base64'));
}
s.close(); ch.kill();
