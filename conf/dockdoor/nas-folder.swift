import AppKit
let N = 1024
func bitmap(_ img: NSImage) -> NSBitmapImageRep {
  let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: N, pixelsHigh: N, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
  img.draw(in: NSRect(x: 0, y: 0, width: N, height: N))
  NSGraphicsContext.restoreGraphicsState()
  return rep
}
let genericImg = NSWorkspace.shared.icon(forFile: CommandLine.arguments[2]); genericImg.size = NSSize(width: N, height: N)
let dlImg = NSWorkspace.shared.icon(forFile: NSHomeDirectory() + "/Downloads"); dlImg.size = NSSize(width: N, height: N)
let g = bitmap(genericImg), d = bitmap(dlImg)
// Usage: swift nas-folder.swift <out.png> <empty-dir> <sf-symbol>
// Draws <sf-symbol> embossed on the macOS folder icon, matched to the Downloads glyph.
// arrow stem pixel (top-left origin) in the Downloads glyph: per-channel darkening ratio
let (sx, sy) = (512, 560)
let a = g.colorAt(x: sx, y: sy)!, b = d.colorAt(x: sx, y: sy)!
let ratio = NSColor(deviceRed: b.redComponent / a.redComponent, green: b.greenComponent / a.greenComponent, blue: b.blueComponent / a.blueComponent, alpha: 1)
print("folder", a, "\nstroke", b, "\nratio", ratio)
// glyph box measured from the circle: x 331-692, y 399-761 (top-left origin)
let box = NSRect(x: 331, y: N - 761, width: 361, height: 362)
let sym = NSImage(systemSymbolName: CommandLine.arguments[3], accessibilityDescription: nil)!
  .withSymbolConfiguration(.init(pointSize: 250, weight: .semibold))!
let s = sym.size, scale = min(box.width * 0.9 / s.width, box.height * 0.9 / s.height)
let r = NSRect(x: box.midX - s.width * scale / 2, y: box.midY - s.height * scale / 2, width: s.width * scale, height: s.height * scale)
func tinted(_ c: NSColor) -> NSImage { NSImage(size: s, flipped: false) { rect in sym.draw(in: rect); c.set(); rect.fill(using: .sourceAtop); return true } }
let out = NSImage(size: NSSize(width: N, height: N))
out.lockFocus()
genericImg.draw(in: NSRect(x: 0, y: 0, width: N, height: N))
tinted(.white).draw(in: r.offsetBy(dx: 0, dy: -3), from: .zero, operation: .sourceOver, fraction: 0.18)   // emboss highlight below
tinted(ratio).draw(in: r, from: .zero, operation: .multiply, fraction: 1)
out.unlockFocus()
try! NSBitmapImageRep(data: out.tiffRepresentation!)!.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
