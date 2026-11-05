#!/bin/bash
# Costruisce app/Pomodoro.app da app/pomodoro.m. L'app è un artefatto: si modifica
# pomodoro.m, poi si rilancia questo. I biomi (biomi/*.html) e la finestra
# (app/pomodoro.html) non serve ricostruirli: l'app li rilegge ogni volta che li apre.
#
# La firma: ad hoc, salvo POMODORO_FIRMA="<nome di un certificato di firma del portachiavi>".
# L'app non chiede permessi, quindi la firma ad hoc basta.
set -e
cd "$(dirname "$0")"
DEST="$(pwd)/app/Pomodoro.app"
rm -rf "$DEST"
mkdir -p "$DEST/Contents/MacOS" "$DEST/Contents/Resources"
clang -O2 -Wall -fobjc-arc -framework Cocoa -framework WebKit -framework ApplicationServices -framework QuartzCore app/pomodoro.m -o "$DEST/Contents/MacOS/Pomodoro"

# L'icona: un pomodoro in pixel art, disegnato qui (16×16, un carattere per pixel)
ICONE="$(mktemp -d)/Pomodoro.iconset"
mkdir -p "$ICONE"
/usr/bin/osascript -l JavaScript - "$ICONE" <<'JXA'
ObjC.import('AppKit');
function run(argv) {
  const disegno = [
    '................',
    '.......gg.......',
    '....g.gGGg.g....',
    '.....gGggGg.....',
    '...rrrgGGgrrr...',
    '..rrrrrggrrrrr..',
    '.rrRRrrrrrrrrrr.',
    '.rRWRrrrrrrrrrr.',
    '.rRRrrrrrrrrrrd.',
    '.rrrrrrrrrrrrrd.',
    '.rrrrrrrrrrrrdd.',
    '.drrrrrrrrrrrdd.',
    '..drrrrrrrrrdd..',
    '...ddrrrrrddd...',
    '.....dddddd.....',
    '................'];
  const colori = { r: [.86, .27, .2], R: [.95, .45, .36], W: [1, .85, .78], d: [.62, .16, .14],
                   g: [.28, .55, .3], G: [.42, .7, .38] };
  for (const lato of [16, 32, 64, 128, 256, 512, 1024]) {
    const rep = $.NSBitmapImageRep.alloc.initWithBitmapDataPlanesPixelsWidePixelsHighBitsPerSampleSamplesPerPixelHasAlphaIsPlanarColorSpaceNameBytesPerRowBitsPerPixel(
      null, lato, lato, 8, 4, true, false, $.NSDeviceRGBColorSpace, 0, 0);
    $.NSGraphicsContext.saveGraphicsState;
    $.NSGraphicsContext.setCurrentContext($.NSGraphicsContext.graphicsContextWithBitmapImageRep(rep));
    const p = lato / 16;
    disegno.forEach((riga, y) => [...riga].forEach((c, x) => {
      if (!colori[c]) return;
      const [r, g, b] = colori[c];
      $.NSColor.colorWithDeviceRedGreenBlueAlpha(r, g, b, 1).setFill;
      $.NSRectFill($.NSMakeRect(x * p, (15 - y) * p, p, p));
    }));
    $.NSGraphicsContext.restoreGraphicsState;
    const png = rep.representationUsingTypeProperties($.NSBitmapImageFileTypePNG, $());
    for (const [nome, l] of [[`icon_${lato}x${lato}.png`, lato], [`icon_${lato / 2}x${lato / 2}@2x.png`, lato / 2]])
      if ((l >= 16 && l <= 512) && !(nome.includes('@2x') && lato === 16)) png.writeToFileAtomically(argv[0] + '/' + nome, true);
  }
}
JXA
iconutil -c icns "$ICONE" -o "$DEST/Contents/Resources/Pomodoro.icns"

cat > "$DEST/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
	<key>CFBundleName</key><string>Pomodoro</string>
	<key>CFBundleExecutable</key><string>Pomodoro</string>
	<key>CFBundleIconFile</key><string>Pomodoro</string>
	<key>CFBundleIdentifier</key><string>local.pomodoro.biomi</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>1.0</string>
	<key>LSMinimumSystemVersion</key><string>12.0</string>
	<key>NSHighResolutionCapable</key><true/>
	<key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign --force --sign "${POMODORO_FIRMA:--}" "$DEST"
echo "Fatto: $DEST"
