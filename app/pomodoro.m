// Pomodoro: dopo N minuti di lavoro, una pausa di K minuti coperta da un bioma in pixel art
// (biomi/*.html). Di base conta Claude in primo piano e copre solo le sue finestre: il resto
// del Mac resta libero, e Claude continua a lavorare sotto. Con "app": "tutto" in
// impostazioni.json conta qualunque app e copre ogni schermo (per lo studio, per il
// computer in generale); con un'altra app, o una lista, conta e copre quelle. Dieci tocchi di fila
// sulla pausa la tolgono prima, e l'uscita resta segnata. Si costruisce con
// ../costruisci.command.
//
//   Pomodoro                     il conto, per sempre (lo lancia il LaunchAgent)
//   Pomodoro --prova 20          una pausa di prova di 20 secondi, poi esce
//   ... --prova 20 --bioma mare  la stessa con quel bioma (la lancia la finestra, «Provalo»)
//
// Aperto a mano (o dal menu in alto) mostra la sua finestra, app/pomodoro.html:
// i minuti, il bioma, la giornata. Scrive impostazioni.json, che il conto
// rilegge ogni secondo.

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import <QuartzCore/QuartzCore.h>

static NSString *const CLAUDE = @"com.anthropic.claudefordesktop";   // l'app che conta e che si copre, se impostazioni.json non ne dice un'altra
static NSString *const TUTTO = @"tutto";                              // "app": "tutto": tutto il Mac
static NSString *const ETICHETTA = @"local.pomodoro.biomi";   // il LaunchAgent, e l'identità dell'app
static NSString *const APRI = @"local.pomodoro.biomi.apri";   // una seconda copia chiede alla prima di aprire la finestra
static const double INATTIVO = 120;   // senza tastiera né mouse da così, non conta
static const double AVVISO = 60;      // l'avviso arriva così prima della pausa
static const int USCITA = 10;         // tocchi di fila per togliere la pausa prima
static const double DI_FILA = 1.2;    // secondi al più fra un tocco e l'altro
static const double LONTANO = 5 * 60; // lontano dal lavoro da così (un'altra app, lo schermo spento, fermo): il conto riparte da zero

// La copertura deve poter prendere la tastiera, così quello che scrivi finisce qui.
// È un pannello che non attiva l'app: macOS non lascia più rubare il primo piano
// all'app davanti, ma lascia a un pannello così diventare la finestra che riceve i tasti.
@interface Copertura : NSPanel
@property WKWebView *web;
@property NSTextField *scritta;       // «ancora N tocchi per uscire»
@property (copy) void (^tocco)(Copertura *);
@end
@implementation Copertura
- (BOOL)canBecomeKeyWindow { return YES; }
- (NSRect)constrainFrameRect:(NSRect)r toScreen:(NSScreen *)s { return r; }  // esattamente sopra la finestra che copre
- (void)keyDown:(NSEvent *)e { if (getenv("POMODORO_TASTI")) fprintf(stderr, "tasto preso dal bioma\n"); }
// I tocchi li conta l'app, qualunque sia il bioma; poi arrivano alla pagina come sempre
- (void)sendEvent:(NSEvent *)e {
  if (e.type == NSEventTypeLeftMouseDown && self.tocco) self.tocco(self);
  [super sendEvent:e];
}
@end

@interface Pomodoro : NSObject <NSApplicationDelegate, NSWindowDelegate, WKScriptMessageHandler, WKNavigationDelegate>
@property NSString *cartella;
@property NSStatusItem *voce;
@property NSMutableDictionary<NSNumber *, Copertura *> *coperture;
@property NSPanel *avviso;
@property NSWindow *finestra;          // il Pomodoro: minuti, bioma, la giornata
@property WKWebView *pagina;
@property double lavoro;      // secondi di lavoro contati dall'ultima pausa
@property double pausaFino;   // epoch in secondi, 0 fuori pausa
@property double pausaDurata; // quanto dura la pausa in corso
@property double resta;       // secondi di lavoro alla prossima pausa
@property BOOL avvisato;
@property double prova;       // > 0: pausa di prova, niente stato, poi esce
@property NSInteger giri;
@property NSInteger tocchi;
@property double ultimoTocco;
@property NSNumber *conSuono;   // la finestra (o lo schermo) la cui copertura suona
// Il giro di ogni secondo gira solo quando serve; fuori, una sveglia sola per la prossima
// cosa da fare (la fine di una pausa, il conto che riparte)
@property NSTimer *giro, *sveglia;
@property NSString *biomaProva;   // nella pausa di prova: il bioma da provare, al posto di quello scelto
@property NSTask *prova20;        // nella finestra: la pausa di prova di un bioma in corso, se c'è
@property NSTimer *bordi;         // con una copertura: guarda se il mouse è ai bordi, per mostrare il margine
@property double ultimoGiro;      // epoch dell'ultimo giro
@property double ultimoAlLavoro;  // epoch dell'ultimo secondo contato: l'app davanti, mani sul Mac
@end

@implementation Pomodoro

- (NSString *)percorso:(NSString *)nome { return [self.cartella stringByAppendingPathComponent:nome]; }

- (NSString *)oggi {
  static NSDateFormatter *f = nil;   // crearne uno costa: l'app chiede la data molte volte al secondo
  if (!f) { f = [NSDateFormatter new]; f.dateFormat = @"yyyy-MM-dd"; }
  return [f stringFromDate:NSDate.date];
}

static NSDictionary *leggiJSON(NSString *p) {
  NSData *d = [NSData dataWithContentsOfFile:p];
  id j = d ? [NSJSONSerialization JSONObjectWithData:d options:0 error:nil] : nil;
  return [j isKindOfClass:NSDictionary.class] ? j : @{};
}

// Un file JSON letto al più una volta ogni «perQuanto» secondi: l'app gira ogni secondo e rilegge
// le impostazioni in tanti punti. Dopo averlo scritto, dimentica() lo fa rileggere subito.
static NSMutableDictionary *memoria = nil;
static NSDictionary *inMemoria(NSString *p, double perQuanto) {
  if (!memoria) memoria = [NSMutableDictionary dictionary];
  double ora = NSDate.date.timeIntervalSince1970;
  NSArray *m = memoria[p];
  if (m && ora - [m[0] doubleValue] < perQuanto) return m[1];
  NSDictionary *j = leggiJSON(p);
  memoria[p] = @[@(ora), j];
  return j;
}
static void dimentica(NSString *p) { [memoria removeObjectForKey:p]; }

static void scriviJSON(id j, NSString *p) {
  NSData *d = [NSJSONSerialization dataWithJSONObject:j options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:nil];
  [d writeToFile:p atomically:YES];
  dimentica(p);
}

// Una riga JSON in coda a un registro di dati/
- (void)aggiungi:(NSDictionary *)riga a:(NSString *)nome {
  NSMutableData *d = [[NSJSONSerialization dataWithJSONObject:riga options:NSJSONWritingSortedKeys error:nil] mutableCopy];
  [d appendData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
  NSString *p = [self percorso:nome];
  [[NSFileManager defaultManager] createDirectoryAtPath:p.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil];
  if (![[NSFileManager defaultManager] fileExistsAtPath:p]) [[NSFileManager defaultManager] createFileAtPath:p contents:nil attributes:nil];
  NSFileHandle *h = [NSFileHandle fileHandleForWritingAtPath:p];
  [h seekToEndOfFile];
  [h writeData:d];
  [h closeFile];
}

- (NSString *)adessoISO {
  NSISO8601DateFormatter *f = [NSISO8601DateFormatter new];
  f.timeZone = NSTimeZone.localTimeZone;
  return [f stringFromDate:NSDate.date];
}

// impostazioni.json: lavoro_minuti, pausa_minuti, bioma; "oggi" vale solo per la sua data;
// luogo: {lat, lon} per il sole dei biomi (giorno, tramonto e notte veri); app: l'identificativo
// dell'app da contare e coprire, una lista di identificativi, o "tutto" (di base Claude)
- (NSDictionary *)impostazioni {
  NSDictionary *j = inMemoria([self percorso:@"impostazioni.json"], 1);
  double lavoro = [j[@"lavoro_minuti"] doubleValue] ?: 45;
  double pausa = [j[@"pausa_minuti"] doubleValue] ?: 5;
  NSDictionary *oggi = j[@"oggi"];
  if ([oggi isKindOfClass:NSDictionary.class] && [oggi[@"data"] isEqual:[self oggi]]) {
    if ([oggi[@"lavoro_minuti"] doubleValue] > 0) lavoro = [oggi[@"lavoro_minuti"] doubleValue];
    if ([oggi[@"pausa_minuti"] doubleValue] > 0) pausa = [oggi[@"pausa_minuti"] doubleValue];
  }
  NSString *bioma = [j[@"bioma"] isKindOfClass:NSString.class] ? j[@"bioma"] : @"stagno";
  NSDictionary *luogo = [j[@"luogo"] isKindOfClass:NSDictionary.class] ? j[@"luogo"] : @{};
  NSMutableArray *app = [NSMutableArray array];
  for (id a in [j[@"app"] isKindOfClass:NSArray.class] ? j[@"app"] : j[@"app"] ? @[j[@"app"]] : @[])
    if ([a isKindOfClass:NSString.class] && [a length]) [app addObject:a];
  if (!app.count) [app addObject:CLAUDE];
  return @{@"lavoro": @(lavoro * 60), @"pausa": @(pausa * 60), @"bioma": bioma,
           @"lavoro_minuti": @(lavoro), @"pausa_minuti": @(pausa), @"luogo": luogo,
           @"app": app, @"tutto": @([app containsObject:TUTTO])};
}

// dati/pause.jsonl: una riga per ogni pausa che comincia, per la giornata
- (void)segnaPausa:(double)minuti {
  if (self.prova > 0) return;
  [self aggiungi:@{@"ora": [self adessoISO], @"giorno": [self oggi], @"minuti": @((long)round(minuti))} a:@"dati/pause.jsonl"];
}

// Quante righe di un registro sono di oggi, e quante di questa settimana (da lunedì)
- (NSDictionary *)contaRighe:(NSString *)nome {
  NSString *testo = [NSString stringWithContentsOfFile:[self percorso:nome] encoding:NSUTF8StringEncoding error:nil];
  NSDateFormatter *f = [NSDateFormatter new];
  f.dateFormat = @"yyyy-MM-dd";
  NSDate *lunedi = nil;
  NSCalendar *iso = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierISO8601];
  [iso rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&lunedi interval:NULL forDate:NSDate.date];
  NSString *oggi = [self oggi], *daLunedi = [f stringFromDate:lunedi ?: [NSCalendar.currentCalendar startOfDayForDate:NSDate.date]];
  NSInteger nOggi = 0, nSettimana = 0;
  for (NSString *riga in [testo componentsSeparatedByString:@"\n"]) {
    NSDictionary *u = riga.length ? [NSJSONSerialization JSONObjectWithData:[riga dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil] : nil;
    NSString *g = [u isKindOfClass:NSDictionary.class] ? u[@"giorno"] : nil;
    if (![g isKindOfClass:NSString.class]) continue;
    if ([g isEqual:oggi]) nOggi++;
    if ([g compare:daLunedi] != NSOrderedAscending) nSettimana++;
  }
  return @{@"oggi": @(nOggi), @"settimana": @(nSettimana)};
}

// dati/stato.json: lo legge anche hook.py, per fermare i messaggi in pausa
- (void)salva {
  if (self.prova > 0) return;
  NSDictionary *s = @{@"lavoro_secondi": @(self.lavoro), @"pausa_fino": @(self.pausaFino),
                      @"pausa_durata": @(self.pausaDurata), @"aggiornato": @(NSDate.date.timeIntervalSince1970),
                      @"lavoro_ultimo": @(self.ultimoAlLavoro), @"giorno": [self oggi], @"spento": @([self spentoFino] > 0)};
  [[NSFileManager defaultManager] createDirectoryAtPath:[self percorso:@"dati"] withIntermediateDirectories:YES attributes:nil error:nil];
  scriviJSON(s, [self percorso:@"dati/stato.json"]);
}

- (void)carica {
  NSDictionary *s = leggiJSON([self percorso:@"dati/stato.json"]);
  double ora = NSDate.date.timeIntervalSince1970;
  if ([s[@"pausa_fino"] doubleValue] > ora) {
    self.pausaFino = [s[@"pausa_fino"] doubleValue];
    self.pausaDurata = [s[@"pausa_durata"] doubleValue] ?: [[self impostazioni][@"pausa"] doubleValue];
    return;
  }
  // Lontano dal lavoro da meno di LONTANO: il conto riprende; se no riparte da zero
  double ultimo = [s[@"lavoro_ultimo"] doubleValue] ?: [s[@"aggiornato"] doubleValue];
  if (ora - ultimo < LONTANO) {
    self.lavoro = [s[@"lavoro_secondi"] doubleValue];
    self.ultimoAlLavoro = ultimo;
  }
}

- (NSString *)davanti { return NSWorkspace.sharedWorkspace.frontmostApplication.bundleIdentifier; }

// L'app davanti è una di quelle che contano? Con "tutto", qualunque app tranne il Pomodoro stesso
- (BOOL)appDavanti {
  NSDictionary *imp = [self impostazioni];
  NSString *f = [self davanti];
  if ([imp[@"tutto"] boolValue]) return f && ![f isEqual:NSBundle.mainBundle.bundleIdentifier];
  return f && [imp[@"app"] containsObject:f];
}

// Coperchio chiuso, schermo spento o bloccato: non è lavoro, anche se il Mac resta sveglio
static BOOL schermoSpento(void) {
  if (CGDisplayIsAsleep(CGMainDisplayID())) return YES;
  NSDictionary *s = CFBridgingRelease(CGSessionCopyCurrentDictionary());
  return [s[@"CGSSessionScreenIsLocked"] boolValue] || (s && ![s[(id)kCGSessionOnConsoleKey] boolValue]);
}

// Spento dalla finestra o dal menu: fino a quando
- (double)spentoFino {
  double s = [inMemoria([self percorso:@"impostazioni.json"], 1)[@"spento_fino"] doubleValue];
  return s > NSDate.date.timeIntervalSince1970 ? s : 0;
}

- (void)tick {
  // Spento: niente conto, niente pause. Una pausa in corso finisce, e conta come uscita
  if ([self spentoFino] > 0) {
    if (self.pausaFino > 0) [self esciPrima];
    if (self.voce) self.voce.button.title = @"🍅 spento";
    if (++self.giri % 5 == 0) [self salva];
    if (self.finestra.isVisible && self.giri % 2 == 0) [self mandaStato];
    [self guardaIlGiro];
    return;
  }
  self.ultimoGiro = NSDate.date.timeIntervalSince1970;
  NSDictionary *imp = [self impostazioni];
  double L = [imp[@"lavoro"] doubleValue], K = [imp[@"pausa"] doubleValue];
  double ora = NSDate.date.timeIntervalSince1970;
  if (self.pausaFino > 0) {
    if (ora >= self.pausaFino) [self finisciPausa];
    else [self copri];
  } else {
    double fermo = CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateCombinedSessionState, kCGAnyInputEventType);
    // Lontano dal lavoro da cinque minuti (un'altra app, lo schermo spento) o fermo da cinque: si riparte da zero
    if (ora - self.ultimoAlLavoro >= LONTANO || fermo >= LONTANO) { self.lavoro = 0; self.avvisato = NO; }
    if (fermo < INATTIVO && [self appDavanti] && !schermoSpento()) {
      self.lavoro += 1;
      self.ultimoAlLavoro = ora;
    }
    self.resta = L - self.lavoro;
    if (!self.avvisato && self.resta <= AVVISO && self.resta > 0) { self.avvisato = YES; [self avvisa:@"Tra un minuto, la pausa."]; }
    if (self.lavoro >= L) [self iniziaPausa:K];
  }
  [self aggiornaVoce];
  if (++self.giri % 5 == 0) [self salva];
  if (self.finestra.isVisible && self.giri % 2 == 0) [self mandaStato];
  [self guardaIlGiro];
}

#pragma mark - Il giro

// Il giro serve con l'app davanti, in pausa (il timer nella barra, la copertura che segue l'app),
// o con la finestra del Pomodoro aperta e in vista. Con lo schermo spento mai.
- (BOOL)serveIlGiro {
  if (schermoSpento()) return NO;
  if (self.finestra.isVisible && (self.finestra.occlusionState & NSWindowOcclusionStateVisible)) return YES;
  if ([self spentoFino] > 0) return NO;
  return self.pausaFino > 0 || [self appDavanti];
}

// Fermo il giro, la prossima cosa che deve succedere da sola: la fine della pausa o dello
// spegnimento, il conto che riparte dopo LONTANO
- (double)prossimaSveglia {
  double ora = NSDate.date.timeIntervalSince1970;
  NSMutableArray<NSNumber *> *quando = [NSMutableArray arrayWithObjects:@(self.pausaFino), @([self spentoFino]), nil];
  if (self.pausaFino == 0 && self.lavoro > 0) [quando addObject:@(self.ultimoAlLavoro + LONTANO)];
  double prima = 0;
  for (NSNumber *q in quando) if (q.doubleValue > ora && (prima == 0 || q.doubleValue < prima)) prima = q.doubleValue;
  return prima;
}

// Accende o ferma il giro: dopo ogni giro, quando un'app passa davanti, al risveglio dello schermo
- (void)guardaIlGiro {
  if ([self serveIlGiro]) {
    [self.sveglia invalidate];
    self.sveglia = nil;
    if (self.giro) return;
    self.giro = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(tick) userInfo:nil repeats:YES];
    self.giro.tolerance = 0.2;
    self.giri = 0;
    if (NSDate.date.timeIntervalSince1970 - self.ultimoGiro >= .5) [self tick];   // se non c'è appena stato
    [self salva];
    return;
  }
  [self.giro invalidate];
  self.giro = nil;
  [self salva];   // fermo, stato.json resta com'è fino al ritorno: lo legge hook.py
  [self.sveglia invalidate];
  double quando = [self prossimaSveglia];
  self.sveglia = quando > 0 ? [NSTimer scheduledTimerWithTimeInterval:MAX(1, quando - NSDate.date.timeIntervalSince1970)
                                                              target:self selector:@selector(tick) userInfo:nil repeats:NO] : nil;
  self.sveglia.tolerance = 1;
}

// Lo schermo si riaccende o si sblocca: lo si guarda subito e fra due secondi (lo sblocco arriva dopo il risveglio)
- (void)risvegliato:(NSNotification *)n {
  [self guardaIlGiro];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [self guardaIlGiro]; });
}

- (void)aggiornaVoce {
  if (!self.voce) return;
  NSString *t;
  if (self.pausaFino > 0) {
    int r = MAX(0, (int)ceil(self.pausaFino - NSDate.date.timeIntervalSince1970));
    t = [NSString stringWithFormat:@"🍅 %d:%02d", r / 60, r % 60];
  } else t = [NSString stringWithFormat:@"🍅 %d'", MAX(1, (int)ceil(self.resta / 60))];
  if (![self.voce.button.title isEqual:t]) self.voce.button.title = t;   // ridisegna solo se cambia
}

#pragma mark - L'avviso

- (void)avvisa:(NSString *)testo {
  if (!self.avviso) {
    NSPanel *p = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 260, 48)
                                            styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                                              backing:NSBackingStoreBuffered defer:NO];
    p.releasedWhenClosed = NO;
    p.level = NSFloatingWindowLevel;
    p.opaque = NO;
    p.backgroundColor = NSColor.clearColor;
    p.hasShadow = YES;
    p.ignoresMouseEvents = YES;
    p.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;
    NSView *v = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 260, 48)];
    v.wantsLayer = YES;
    v.layer.cornerRadius = 12;
    v.layer.backgroundColor = [NSColor colorWithRed:.06 green:.16 blue:.17 alpha:.96].CGColor;
    NSTextField *l = [NSTextField labelWithString:@""];
    l.tag = 1;
    l.font = [NSFont systemFontOfSize:14 weight:NSFontWeightMedium];
    l.textColor = [NSColor colorWithRed:.81 green:.88 blue:.83 alpha:1];
    l.alignment = NSTextAlignmentCenter;
    l.frame = NSMakeRect(0, 14, 260, 20);
    [v addSubview:l];
    p.contentView = v;
    self.avviso = p;
  }
  NSTextField *l = [self.avviso.contentView viewWithTag:1];
  l.stringValue = testo;
  CGFloat largo = MAX(260, ceil(l.intrinsicContentSize.width) + 40);
  [self.avviso setContentSize:NSMakeSize(largo, 48)];
  l.frame = NSMakeRect(0, 14, largo, 20);
  NSRect s = NSScreen.mainScreen.visibleFrame;
  [self.avviso setFrameOrigin:NSMakePoint(NSMaxX(s) - largo - 16, NSMaxY(s) - 48 - 16)];
  [self.avviso orderFrontRegardless];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [self.avviso orderOut:nil]; });
}

#pragma mark - La pausa

- (void)iniziaPausa:(double)K {
  [self segnaPausa:K / 60];
  self.pausaFino = NSDate.date.timeIntervalSince1970 + K;
  self.pausaDurata = K;
  self.lavoro = 0;
  self.avvisato = NO;
  [self toglieTutto];
  self.tocchi = 0;
  [self.avviso orderOut:nil];
  [self salva];
  [self copri];
  [self guardaIlGiro];
}

// Chiudere la finestra non ferma il suono: la pagina resta viva finché vive
// l'app. Così prima la si svuota, e il processo della pagina se ne va.
- (void)togli:(Copertura *)c {
  [c.web stopLoading];
  [c.web loadHTMLString:@"" baseURL:nil];
  [c.web removeFromSuperview];
  c.web = nil;
  [c close];
}

- (void)toglieTutto {
  for (Copertura *c in self.coperture.allValues) [self togli:c];
  [self.coperture removeAllObjects];
  self.conSuono = nil;
}

- (void)finisciPausa {
  self.pausaFino = 0;
  [self toglieTutto];
  [self salva];
  if (self.prova > 0) [NSApp terminate:nil];
}

- (void)toccato:(Copertura *)c {
  double ora = NSDate.date.timeIntervalSince1970;
  self.tocchi = ora - self.ultimoTocco < DI_FILA ? self.tocchi + 1 : 1;
  self.ultimoTocco = ora;
  if (self.tocchi >= USCITA) { [self esciPrima]; return; }
  if (self.tocchi < 4) return;
  // Da metà strada in poi lo dice, così chi tocca l'acqua per gioco non esce per sbaglio
  NSInteger restano = USCITA - self.tocchi;
  c.scritta.stringValue = [NSString stringWithFormat:@"ancora %ld %@ per uscire · resterà segnato",
                           (long)restano, restano == 1 ? @"tocco" : @"tocchi"];
  c.scritta.alphaValue = 1;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DI_FILA * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    if (NSDate.date.timeIntervalSince1970 - self.ultimoTocco >= DI_FILA) c.scritta.alphaValue = 0;
  });
}

// dati/uscite.jsonl: una riga per ogni pausa tolta prima con i dieci tocchi (o spegnendo)
- (void)esciPrima {
  double mancavano = MAX(0, self.pausaFino - NSDate.date.timeIntervalSince1970);
  self.tocchi = 0;
  if (self.prova > 0) fprintf(stderr, "uscita con i tocchi (prova: non segnata), mancavano %.0f s\n", mancavano);
  else [self aggiungi:@{@"ora": [self adessoISO], @"giorno": [self oggi], @"mancavano_secondi": @((long)round(mancavano))}
                    a:@"dati/uscite.jsonl"];
  [self finisciPausa];
}

- (NSURL *)scena:(BOOL)suono {
  NSString *bioma = self.biomaProva ?: [self impostazioni][@"bioma"];
  NSString *p = [self percorso:[NSString stringWithFormat:@"biomi/%@.html", bioma]];
  if (![[NSFileManager defaultManager] fileExistsAtPath:p]) p = [self percorso:@"biomi/stagno.html"];
  NSURLComponents *u = [NSURLComponents componentsWithURL:[NSURL fileURLWithPath:p] resolvingAgainstBaseURL:NO];
  NSMutableArray *q = [@[[NSURLQueryItem queryItemWithName:@"fine" value:[NSString stringWithFormat:@"%.0f", self.pausaFino * 1000]],
                         [NSURLQueryItem queryItemWithName:@"suono" value:suono ? @"1" : @"0"]] mutableCopy];
  [q addObjectsFromArray:[self giornata]];
  // Un brano a caso dai file sciolti in musica/, per i biomi senza la loro cartella (musica/<bioma>/)
  NSArray *brani = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self percorso:@"musica"] error:nil]
                    filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self MATCHES[c] '.*\\\\.(mp3|m4a|wav|ogg|aac)$'"]];
  if (suono && brani.count) [q addObject:[NSURLQueryItem queryItemWithName:@"musica" value:brani[arc4random_uniform((uint32_t)brani.count)]]];
  u.queryItems = q;
  return u.URL;
}

// Cosa arriva al bioma oltre al timer: uscite=N (di oggi) e il luogo del sole (lat, lon).
// Cosa farne lo decide il bioma.
- (NSArray<NSURLQueryItem *> *)giornata {
  NSMutableArray *q = [NSMutableArray array];
  [q addObject:[NSURLQueryItem queryItemWithName:@"uscite" value:[[self contaRighe:@"dati/uscite.jsonl"][@"oggi"] stringValue]]];
  NSDictionary *luogo = [self impostazioni][@"luogo"];
  for (NSString *k in @[@"lat", @"lon"])
    if ([luogo[k] isKindOfClass:NSNumber.class]) [q addObject:[NSURLQueryItem queryItemWithName:k value:[NSString stringWithFormat:@"%g", [luogo[k] doubleValue]]]];
  return q;
}

- (Copertura *)nuovaCopertura:(NSRect)f suono:(BOOL)suono {
  Copertura *c = [[Copertura alloc] initWithContentRect:f styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                                                backing:NSBackingStoreBuffered defer:NO];
  c.releasedWhenClosed = NO;
  c.hidesOnDeactivate = NO;
  c.becomesKeyOnlyIfNeeded = NO;
  c.hasShadow = NO;
  c.opaque = NO;
  c.backgroundColor = NSColor.clearColor;   // il fondo scuro sta nel layer, sotto la maschera del margine
  c.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;
  NSView *fondo = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, f.size.width, f.size.height)];
  fondo.wantsLayer = YES;
  fondo.layer.backgroundColor = [NSColor colorWithRed:.03 green:.09 blue:.1 alpha:1].CGColor;
  CALayer *maschera = [CALayer layer];
  maschera.backgroundColor = NSColor.blackColor.CGColor;
  maschera.frame = fondo.bounds;
  fondo.layer.mask = maschera;
  WKWebViewConfiguration *cfg = [WKWebViewConfiguration new];
  cfg.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
  WKWebView *web = [[WKWebView alloc] initWithFrame:fondo.bounds configuration:cfg];
  web.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  [web setValue:@NO forKey:@"drawsBackground"];
  [web loadFileURL:[self scena:suono] allowingReadAccessToURL:[NSURL fileURLWithPath:self.cartella]];
  [fondo addSubview:web];
  // Sopra la fascia dell'invito (l'ultimo sesto), dove nel bioma non passa niente
  NSTextField *s = [NSTextField labelWithString:@""];
  s.font = [NSFont systemFontOfSize:13 weight:NSFontWeightMedium];
  s.textColor = [NSColor colorWithRed:.81 green:.88 blue:.83 alpha:.85];
  s.alignment = NSTextAlignmentCenter;
  s.frame = NSMakeRect(0, f.size.height * .17, f.size.width, 20);
  s.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin | NSViewMaxYMargin;
  s.alphaValue = 0;
  s.wantsLayer = YES;
  [fondo addSubview:s];
  c.contentView = fondo;
  c.web = web;
  c.scritta = s;
  __weak Pomodoro *io = self;
  c.tocco = ^(Copertura *x) { [io toccato:x]; };
  return c;
}

// 5 mm veri sullo schermo dove sta la finestra (dalla misura fisica del pannello)
static CGFloat mezzoCentimetro(NSRect f) {
  for (NSScreen *s in NSScreen.screens) {
    if (!NSIntersectsRect(s.frame, f)) continue;
    CGSize mm = CGDisplayScreenSize([s.deviceDescription[@"NSScreenNumber"] unsignedIntValue]);
    if (mm.width > 0) return round(5 * s.frame.size.width / mm.width);
  }
  return 20;
}

// Una copertura su ogni finestra visibile delle app che contano, appena sopra di lei: le finestre
// delle altre app che le stanno sopra restano sopra. Con "tutto", una copertura per schermo, sopra
// ogni finestra (la barra in alto e il Dock restano: il 🍅 dice quanto manca).
- (void)copri {
  NSDictionary *imp = [self impostazioni];
  NSMutableSet *viste = [NSMutableSet set];
  if ([imp[@"tutto"] boolValue]) {
    for (NSScreen *s in NSScreen.screens) {
      NSNumber *chiave = @(-1 - [s.deviceDescription[@"NSScreenNumber"] integerValue]);   // negativa: non è una finestra
      [viste addObject:chiave];
      Copertura *c = self.coperture[chiave];
      if (!c) {
        BOOL suono = !self.conSuono;
        self.coperture[chiave] = c = [self nuovaCopertura:s.frame suono:suono];
        c.level = NSFloatingWindowLevel;
        if (suono) self.conSuono = chiave;
      }
      else if (!NSEqualRects(c.frame, s.frame)) [c setFrame:s.frame display:YES];
      [c orderFrontRegardless];
    }
  }
  NSMutableSet *pid = [NSMutableSet set];
  if (![imp[@"tutto"] boolValue])
    for (NSString *a in imp[@"app"])
      for (NSRunningApplication *r in [NSRunningApplication runningApplicationsWithBundleIdentifier:a]) [pid addObject:@(r.processIdentifier)];
  NSArray *info = pid.count ? CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID)) : @[];
  CGFloat alto = NSScreen.screens.firstObject.frame.size.height;
  for (NSDictionary *w in info) {
    if (![pid containsObject:w[(id)kCGWindowOwnerPID]] || [w[(id)kCGWindowLayer] intValue] != 0) continue;
    CGRect r;
    CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)w[(id)kCGWindowBounds], &r);
    if (r.size.width < 300 || r.size.height < 200) continue;
    NSNumber *wid = w[(id)kCGWindowNumber];
    [viste addObject:wid];
    NSRect f = NSMakeRect(r.origin.x, alto - r.origin.y - r.size.height, r.size.width, r.size.height);
    Copertura *c = self.coperture[wid];
    if (!c) {
      BOOL suono = !self.conSuono;
      self.coperture[wid] = c = [self nuovaCopertura:f suono:suono];
      if (suono) self.conSuono = wid;
    }
    else if (!NSEqualRects(c.frame, f)) [c setFrame:f display:YES];
    [c orderWindow:NSWindowAbove relativeTo:wid.integerValue];
  }
  for (NSNumber *wid in self.coperture.allKeys)
    if (![viste containsObject:wid]) { [self togli:self.coperture[wid]]; [self.coperture removeObjectForKey:wid]; }
  // Sparita la finestra che suonava, il suono passa a un'altra copertura (la sua scena riparte)
  if (self.conSuono && !self.coperture[self.conSuono]) {
    self.conSuono = self.coperture.allKeys.firstObject;
    Copertura *c = self.coperture[self.conSuono];
    [c.web loadFileURL:[self scena:YES] allowingReadAccessToURL:[NSURL fileURLWithPath:self.cartella]];
  }
  if ([self appDavanti] || [imp[@"tutto"] boolValue]) [self prendiTastiera];
  if (self.coperture.count && !self.bordi) {
    self.bordi = [NSTimer scheduledTimerWithTimeInterval:.08 target:self selector:@selector(guardaIBordi) userInfo:nil repeats:YES];
    self.bordi.tolerance = .02;
  }
}

// La copertura prende tutta la finestra; col mouse ai bordi (a un centimetro dall'orlo, dentro o
// fuori) si ritira di mezzo centimetro tutt'intorno, e si vede la finestra sotto. La copertura non
// cambia misura (il bioma non si ridisegna): la maschera del layer si stringe. Quelle degli schermi no:
// ai bordi di uno schermo il mouse ci va sempre.
- (void)guardaIBordi {
  if (!self.coperture.count) { [self.bordi invalidate]; self.bordi = nil; return; }
  NSPoint m = NSEvent.mouseLocation;
  for (NSNumber *chiave in self.coperture) {
    Copertura *c = self.coperture[chiave];
    CALayer *maschera = c.contentView.layer.mask;
    if (!maschera || chiave.integerValue < 0) continue;
    CGFloat mezzo = mezzoCentimetro(c.frame);
    BOOL ai = NSPointInRect(m, NSInsetRect(c.frame, -2 * mezzo, -2 * mezzo)) && !NSPointInRect(m, NSInsetRect(c.frame, 2 * mezzo, 2 * mezzo));
    NSRect dentro = c.contentView.bounds;
    if (ai) dentro = NSInsetRect(dentro, mezzo, mezzo);
    if (NSEqualRects(maschera.frame, dentro)) continue;
    [CATransaction begin];
    [CATransaction setAnimationDuration:.18];
    maschera.frame = dentro;
    [CATransaction commit];
  }
}

// Se in pausa torni sull'app (o, con "tutto", sempre), la tastiera torna al bioma
- (void)prendiTastiera {
  Copertura *c = self.coperture.allValues.firstObject;
  if (!c || c.isKeyWindow) return;
  [c makeKeyAndOrderFront:nil];
}

// Un'app passa davanti: se è una di quelle che contano il giro riparte, se no si ferma (salvo in pausa)
- (void)attivata:(NSNotification *)n {
  NSRunningApplication *app = n.userInfo[NSWorkspaceApplicationKey];
  NSDictionary *imp = [self impostazioni];
  if (self.pausaFino > 0 && ([imp[@"tutto"] boolValue] || [imp[@"app"] containsObject:app.bundleIdentifier])) [self copri];
  [self guardaIlGiro];
}

#pragma mark - La finestra del Pomodoro

- (void)apriPomodoro {
  if (self.prova > 0) return;
  if (!self.finestra) {
    NSWindow *w = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 760, 760)
                                              styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable |
                                                        NSWindowStyleMaskResizable
                                                backing:NSBackingStoreBuffered defer:NO];
    w.title = @"Pomodoro";
    w.titlebarAppearsTransparent = YES;
    w.titleVisibility = NSWindowTitleHidden;
    w.releasedWhenClosed = NO;
    w.minSize = NSMakeSize(560, 560);
    w.backgroundColor = [NSColor colorWithRed:.03 green:.09 blue:.1 alpha:1];
    w.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    w.delegate = self;
    WKWebViewConfiguration *cfg = [WKWebViewConfiguration new];
    [cfg.userContentController addScriptMessageHandler:self name:@"pomodoro"];
    WKWebView *web = [[WKWebView alloc] initWithFrame:w.contentView.bounds configuration:cfg];
    web.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [web setValue:@NO forKey:@"drawsBackground"];
    web.navigationDelegate = self;
    [web loadFileURL:[NSURL fileURLWithPath:[self percorso:@"app/pomodoro.html"]]
         allowingReadAccessToURL:[NSURL fileURLWithPath:self.cartella]];
    [w.contentView addSubview:web];
    [w center];
    self.finestra = w;
    self.pagina = web;
  }
  if (@available(macOS 14.0, *)) [NSApp activate]; else [NSApp activateIgnoringOtherApps:YES];
  [self.finestra makeKeyAndOrderFront:nil];
  [self mandaStato];
  [self guardaIlGiro];
}

- (void)webView:(WKWebView *)w didFinishNavigation:(WKNavigation *)n { [self mandaStato]; }

// Chiusa, la pagina si svuota: le anteprime dei biomi non girano per niente
- (void)windowWillClose:(NSNotification *)n {
  if (n.object != self.finestra) return;
  [self.pagina.configuration.userContentController removeScriptMessageHandlerForName:@"pomodoro"];
  [self.pagina loadHTMLString:@"" baseURL:nil];
  self.pagina = nil;
  self.finestra = nil;
  dispatch_async(dispatch_get_main_queue(), ^{ [self guardaIlGiro]; });
}

// La finestra del Pomodoro coperta da altre o di nuovo in vista: il giro la segue
- (void)windowDidChangeOcclusionState:(NSNotification *)n {
  if (n.object == self.finestra) [self guardaIlGiro];
}

- (void)mandaStato {
  if (!self.pagina) return;
  NSDictionary *imp = [self impostazioni];
  NSArray *file = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self percorso:@"biomi"] error:nil];
  NSMutableArray *biomi = [NSMutableArray array];
  for (NSString *f in [file sortedArrayUsingSelector:@selector(compare:)])
    if ([f.pathExtension isEqual:@"html"]) [biomi addObject:f.stringByDeletingPathExtension];
  NSMutableDictionary *query = [NSMutableDictionary dictionary];
  for (NSURLQueryItem *i in [self giornata]) query[i.name] = i.value;
  NSDictionary *s = @{
    @"oggi": [self oggi],
    @"file": inMemoria([self percorso:@"impostazioni.json"], 1),
    @"lavoro_minuti": imp[@"lavoro_minuti"], @"pausa_minuti": imp[@"pausa_minuti"],
    @"resta_secondi": @(self.resta), @"pausa_durata_minuti": @(self.pausaDurata / 60), @"spento_fino": @([self spentoFino]),
    @"pause_oggi": [self contaRighe:@"dati/pause.jsonl"][@"oggi"], @"uscite": [self contaRighe:@"dati/uscite.jsonl"],
    @"in_prova": self.prova20.isRunning ? self.prova20.arguments.lastObject : NSNull.null,
    @"bioma": imp[@"bioma"], @"biomi": biomi, @"giornata": query, @"app": imp[@"app"], @"tutto": imp[@"tutto"],
    @"lavoro_secondi": @(self.lavoro), @"pausa_fino": @(self.pausaFino), @"ora": @(NSDate.date.timeIntervalSince1970),
  };
  NSData *d = [NSJSONSerialization dataWithJSONObject:s options:0 error:nil];
  NSString *js = [NSString stringWithFormat:@"window.stato && stato(%@)", [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding]];
  [self.pagina evaluateJavaScript:js completionHandler:nil];
}

// Dalla pagina: {tipo: "tempi", lavoro, pausa, per: "oggi"|"sempre"} · {tipo: "togli_oggi"} · {tipo: "bioma", nome}
// · {tipo: "modo", tutto: sì|no}
// · {tipo: "prova", nome} · {tipo: "spegni", minuti | null (fino a mezzanotte)} · {tipo: "accendi"}
- (void)userContentController:(WKUserContentController *)u didReceiveScriptMessage:(WKScriptMessage *)m {
  NSDictionary *b = [m.body isKindOfClass:NSDictionary.class] ? m.body : @{};
  NSString *tipo = b[@"tipo"];
  NSMutableDictionary *j = [leggiJSON([self percorso:@"impostazioni.json"]) mutableCopy];
  if ([tipo isEqual:@"tempi"]) {
    NSInteger lavoro = MIN(MAX([b[@"lavoro"] integerValue], 1), 240), pausa = MIN(MAX([b[@"pausa"] integerValue], 1), 60);
    if ([b[@"per"] isEqual:@"oggi"]) j[@"oggi"] = @{@"data": [self oggi], @"lavoro_minuti": @(lavoro), @"pausa_minuti": @(pausa)};
    else { j[@"lavoro_minuti"] = @(lavoro); j[@"pausa_minuti"] = @(pausa); j[@"oggi"] = NSNull.null; }
  } else if ([tipo isEqual:@"modo"]) {   // cosa conta e cosa copre: tutto il Mac, o di nuovo Claude
    if ([b[@"tutto"] boolValue]) j[@"app"] = TUTTO; else [j removeObjectForKey:@"app"];
  } else if ([tipo isEqual:@"prova"] && [b[@"nome"] isKindOfClass:NSString.class]) {
    [self provaIlBioma:b[@"nome"]];
    return;
  } else if ([tipo isEqual:@"spegni"]) {
    double fino = [b[@"minuti"] isKindOfClass:NSNumber.class] ? NSDate.date.timeIntervalSince1970 + [b[@"minuti"] doubleValue] * 60
                : [[NSCalendar.currentCalendar startOfDayForDate:NSDate.date] timeIntervalSince1970] + 86400;   // fino a mezzanotte
    j[@"spento_fino"] = @(round(fino));
  } else if ([tipo isEqual:@"accendi"]) {
    [j removeObjectForKey:@"spento_fino"];
  } else if ([tipo isEqual:@"togli_oggi"]) {
    j[@"oggi"] = NSNull.null;
  } else if ([tipo isEqual:@"bioma"] && [b[@"nome"] isKindOfClass:NSString.class] &&
             [[NSFileManager defaultManager] fileExistsAtPath:[self percorso:[NSString stringWithFormat:@"biomi/%@.html", b[@"nome"]]]]) {
    j[@"bioma"] = b[@"nome"];
  } else return;
  scriviJSON(j, [self percorso:@"impostazioni.json"]);
  // Con una soglia nuova più bassa del già contato, la pausa arriva comunque con il suo minuto d'avviso
  if ([tipo isEqual:@"tempi"] || [tipo isEqual:@"togli_oggi"]) {
    double L = [[self impostazioni][@"lavoro"] doubleValue];
    if (self.pausaFino == 0 && self.lavoro > L - AVVISO) self.lavoro = MAX(0, L - AVVISO);
    self.avvisato = NO;
    [self salva];
  }
  if ([tipo isEqual:@"spegni"] || [tipo isEqual:@"accendi"]) [self tick];
  [self mandaStato];
}

// «Provalo · 20 secondi» sotto un bioma: una pausa di prova in un'altra copia dell'app (--prova, che non tocca
// il conto né segna uscite), sopra l'app come quella vera. La finestra si fa da parte e torna alla fine.
- (void)provaIlBioma:(NSString *)nome {
  if (self.prova20.isRunning || self.pausaFino > 0 ||
      ![[NSFileManager defaultManager] fileExistsAtPath:[self percorso:[NSString stringWithFormat:@"biomi/%@.html", nome]]]) return;
  NSTask *t = [NSTask new];
  t.executableURL = [NSURL fileURLWithPath:NSBundle.mainBundle.executablePath];
  t.arguments = @[@"--prova", @"20", @"--bioma", nome];
  __weak Pomodoro *io = self;
  t.terminationHandler = ^(NSTask *x) {
    dispatch_async(dispatch_get_main_queue(), ^{
      io.prova20 = nil;
      [io.finestra orderFrontRegardless];   // torna davanti, senza rubare la tastiera
      [io mandaStato];
    });
  };
  if (![t launchAndReturnError:nil]) return;
  self.prova20 = t;
  [self.finestra orderOut:nil];
}

#pragma mark - Il menu

- (void)pausaAdesso { [self iniziaPausa:[[self impostazioni][@"pausa"] doubleValue]]; }
- (void)scriviSpento:(NSNumber *)fino {
  NSMutableDictionary *j = [leggiJSON([self percorso:@"impostazioni.json"]) mutableCopy];
  if (fino) j[@"spento_fino"] = fino; else [j removeObjectForKey:@"spento_fino"];
  scriviJSON(j, [self percorso:@"impostazioni.json"]);
  [self tick];
}
- (void)spegniUnOra { [self scriviSpento:@(round(NSDate.date.timeIntervalSince1970 + 3600))]; }
- (void)riaccendi { [self scriviSpento:nil]; }
- (BOOL)validateMenuItem:(NSMenuItem *)i {
  if (i.action == @selector(riaccendi)) return [self spentoFino] > 0;
  if (i.action == @selector(spegniUnOra)) return [self spentoFino] == 0;
  if (i.action == @selector(pausaAdesso)) return [self spentoFino] == 0 && self.pausaFino == 0;
  return YES;
}
- (void)ricomincia {
  self.lavoro = 0;
  self.avvisato = NO;
  self.resta = [[self impostazioni][@"lavoro"] doubleValue];
  [self aggiornaVoce];
  [self salva];
}
- (void)apriCartella { [NSWorkspace.sharedWorkspace openURL:[NSURL fileURLWithPath:self.cartella]]; }

// Il menu del 🍅: in cima «Pausa adesso», poi il resto
- (NSMenu *)menu {
  NSMenu *m = [NSMenu new];
  [m addItemWithTitle:@"Pausa adesso" action:@selector(pausaAdesso) keyEquivalent:@""].target = self;
  [m addItemWithTitle:@"Apri il Pomodoro" action:@selector(apriPomodoro) keyEquivalent:@""].target = self;
  [m addItem:NSMenuItem.separatorItem];
  [m addItemWithTitle:@"Spegni per un'ora" action:@selector(spegniUnOra) keyEquivalent:@""].target = self;
  [m addItemWithTitle:@"Riaccendi" action:@selector(riaccendi) keyEquivalent:@""].target = self;
  [m addItemWithTitle:@"Ricomincia il conto" action:@selector(ricomincia) keyEquivalent:@""].target = self;
  [m addItemWithTitle:@"Apri la cartella" action:@selector(apriCartella) keyEquivalent:@""].target = self;
  [m addItem:NSMenuItem.separatorItem];
  [m addItemWithTitle:@"Esci" action:@selector(terminate:) keyEquivalent:@""];
  return m;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)a hasVisibleWindows:(BOOL)v { [self apriPomodoro]; return NO; }

- (void)applicationDidFinishLaunching:(NSNotification *)n {
  // La cartella del progetto: due livelli sopra Pomodoro.app (app/Pomodoro.app → la radice)
  self.cartella = [[NSBundle.mainBundle.bundlePath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
  self.coperture = [NSMutableDictionary dictionary];
  NSArray *arg = NSProcessInfo.processInfo.arguments;
  NSUInteger i = [arg indexOfObject:@"--prova"];
  if (i != NSNotFound && i + 1 < arg.count) self.prova = [arg[i + 1] doubleValue];

  if (self.prova > 0) {
    self.pausaFino = NSDate.date.timeIntervalSince1970 + self.prova;
    NSUInteger b = [arg indexOfObject:@"--bioma"];
    if (b != NSNotFound && b + 1 < arg.count) self.biomaProva = arg[b + 1];
    [self copri];
  } else {
    // Ce n'è già uno: gli si chiede di aprire la finestra, e questo se ne va
    for (NSRunningApplication *a in [NSRunningApplication runningApplicationsWithBundleIdentifier:NSBundle.mainBundle.bundleIdentifier])
      if (a.processIdentifier != getpid()) {
        [NSDistributedNotificationCenter.defaultCenter postNotificationName:APRI object:nil userInfo:nil deliverImmediately:YES];
        [NSApp terminate:nil];
        return;
      }
    [NSDistributedNotificationCenter.defaultCenter addObserver:self selector:@selector(apriPomodoro) name:APRI object:nil];
    [self carica];
    self.voce = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    self.voce.button.font = [NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightRegular];
    self.voce.menu = [self menu];
    // Acceso a mano (doppio clic), non dal LaunchAgent: si apre la finestra
    if (![NSProcessInfo.processInfo.environment[@"XPC_SERVICE_NAME"] isEqual:ETICHETTA]) [self apriPomodoro];
  }
  NSNotificationCenter *ws = NSWorkspace.sharedWorkspace.notificationCenter;
  [ws addObserver:self selector:@selector(attivata:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
  for (NSString *nome in @[NSWorkspaceScreensDidWakeNotification, NSWorkspaceDidWakeNotification, NSWorkspaceSessionDidBecomeActiveNotification])
    [ws addObserver:self selector:@selector(risvegliato:) name:nome object:nil];
  [NSDistributedNotificationCenter.defaultCenter addObserver:self selector:@selector(risvegliato:) name:@"com.apple.screenIsUnlocked" object:nil];
  [self tick];   // un giro, poi guardaIlGiro decide se continuare
}

- (void)applicationWillTerminate:(NSNotification *)n { [self salva]; }

@end

int main(void) {
  @autoreleasepool {
    NSApplication *app = NSApplication.sharedApplication;
    Pomodoro *p = [Pomodoro new];
    app.delegate = p;
    app.activationPolicy = NSApplicationActivationPolicyAccessory;
    [app run];
  }
  return 0;
}
