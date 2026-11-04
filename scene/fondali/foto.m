// foto <url> <png> [secondi] [larghezza] [altezza]: fotografa una scena nella WKWebView, come la vede il Pomodoro.
// clang -fobjc-arc -framework Cocoa -framework WebKit scene/fondali/foto.m -o /tmp/foto
// La finestra sta fuori dallo schermo tranne due pixel a destra (sennò la pagina è nascosta e non disegna),
// non prende clic né tastiera. Apre comunque una finestra: per le prove automatiche è meglio Chrome senza schermo (LEGGIMI.md).
// PRIMA="for (let i = 1; i < 900; i++) frame(i * 16.7); 1" fa girare i fotogrammi a mano: serve a Mac bloccato, quando la pagina è nascosta e non disegna.
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
int main(int argc, char **argv) { @autoreleasepool {
  [NSApplication sharedApplication]; [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
  NSString *url = @(argv[1]), *out = @(argv[2]);
  double sec = argc > 3 ? atof(argv[3]) : 4, W = argc > 4 ? atof(argv[4]) : 900, H = argc > 5 ? atof(argv[5]) : 560;
  NSPanel *w = [[NSPanel alloc] initWithContentRect:NSMakeRect(NSScreen.mainScreen.frame.size.width - 2, 0, W, H) styleMask:NSWindowStyleMaskBorderless|NSWindowStyleMaskNonactivatingPanel backing:NSBackingStoreBuffered defer:NO];
  w.releasedWhenClosed = NO; w.alphaValue = 0.01; w.ignoresMouseEvents = YES; w.level = NSFloatingWindowLevel;
  WKWebViewConfiguration *cfg = [WKWebViewConfiguration new];
  WKWebView *web = [[WKWebView alloc] initWithFrame:NSMakeRect(0,0,W,H) configuration:cfg];
  [web loadFileURL:[NSURL URLWithString:url] allowingReadAccessToURL:[NSURL URLWithString:@"file:///"]];
  w.contentView = web; [w orderFrontRegardless];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, sec*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [web evaluateJavaScript:@(getenv("PRIMA") ?: "0") completionHandler:^(id r0, NSError *e0) {
    if (e0) fprintf(stderr, "%s\n", e0.description.UTF8String);
    [web takeSnapshotWithConfiguration:nil completionHandler:^(NSImage *im, NSError *e) {
      NSBitmapImageRep *r = [[NSBitmapImageRep alloc] initWithData:im.TIFFRepresentation];
      [[r representationUsingType:NSBitmapImageFileTypePNG properties:@{}] writeToFile:out atomically:YES];
      [NSApp terminate:nil];
    }]; }];
  });
  [NSApp run];
}}
