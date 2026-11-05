// guarda <bioma> [minuti] [ora, es. 22:30] [altro, es. esagerato=3&studiato=1]: apre biomi/<bioma>.html in una finestra normale, con
// suono e tocco, come la vede il Pomodoro in pausa ma senza coprire Claude.
// Per far vedere (e sentire) un bioma a una persona. Si chiude con la finestra (o ⌘Q).
// Non prende mai il primo piano da sola: chi lo guarda magari sta lavorando.
// clang -fobjc-arc -framework Cocoa -framework WebKit biomi/fondali/guarda.m -o /tmp/guarda
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface Delegato : NSObject <NSApplicationDelegate, NSWindowDelegate> @end
@implementation Delegato
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)a { return YES; }
@end

int main(int argc, char **argv) { @autoreleasepool {
  NSApplication *app = [NSApplication sharedApplication];
  app.activationPolicy = NSApplicationActivationPolicyRegular;
  Delegato *del = [Delegato new]; app.delegate = del;
  NSString *bioma = argc > 1 ? @(argv[1]) : @"stagno";
  double minuti = argc > 2 ? atof(argv[2]) : 5;
  // la cartella del progetto: POMODORO, o quella da cui lo si lancia
  NSString *cartella = NSProcessInfo.processInfo.environment[@"POMODORO"] ?: NSFileManager.defaultManager.currentDirectoryPath;
  NSString *scena = [cartella stringByAppendingFormat:@"/biomi/%@.html", bioma];
  NSURLComponents *u = [NSURLComponents componentsWithURL:[NSURL fileURLWithPath:scena] resolvingAgainstBaseURL:NO];
  u.query = [NSString stringWithFormat:@"suono=1&fine=%.0f%@%@", (NSDate.date.timeIntervalSince1970 + minuti * 60) * 1000,
             argc > 3 && argv[3][0] ? [@"&ora=" stringByAppendingString:@(argv[3])] : @"",
             argc > 4 ? [@"&" stringByAppendingString:@(argv[4])] : @""];

  NSRect s = NSScreen.mainScreen.visibleFrame;
  NSRect f = NSInsetRect(s, s.size.width * .1, s.size.height * .1);
  NSWindow *w = [[NSWindow alloc] initWithContentRect:f styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable
                                              backing:NSBackingStoreBuffered defer:NO];
  w.title = [NSString stringWithFormat:@"Bioma: %@", bioma];
  w.releasedWhenClosed = NO;
  WKWebViewConfiguration *cfg = [WKWebViewConfiguration new];
  cfg.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
  WKWebView *web = [[WKWebView alloc] initWithFrame:w.contentView.bounds configuration:cfg];
  web.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  [web loadFileURL:u.URL allowingReadAccessToURL:[NSURL fileURLWithPath:cartella]];
  w.contentView = web;
  // si mette davanti ma non prende la tastiera: ci si clicca quando si vuole
  [w orderFrontRegardless];
  [app run];
}}
