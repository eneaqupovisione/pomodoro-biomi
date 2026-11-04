"""La seconda sicura del Pomodoro: in pausa, un messaggio a Claude non parte.

Hook UserPromptSubmit di Claude Code (facoltativo: INSTALLA.md). Legge dati/stato.json
(lo scrive Pomodoro.app) e, se la pausa non è finita, blocca il messaggio dicendo quanto
manca. Spento dalla finestra, non ferma niente. Se qualcosa si rompe, il messaggio passa:
il Pomodoro non ferma mai per un suo errore.
"""
import json
import time
from pathlib import Path

STATO = Path(__file__).resolve().parent / "dati" / "stato.json"

try:
    stato = json.loads(STATO.read_text())
    resto = stato.get("pausa_fino", 0) - time.time()
    if not stato.get("spento") and resto > 0:
        m, s = divmod(int(resto) + 1, 60)
        print(json.dumps({"decision": "block", "reason": f"Sei in pausa: finisce tra {m}:{s:02d}."}))
except Exception:
    pass
