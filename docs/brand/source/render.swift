// Rasterize the editable SVG masters with the macOS system renderer.
import AppKit

let args = CommandLine.arguments
guard args.count == 5,
      let source = NSImage(contentsOfFile: args[1]),
      let width = Int(args[3]), let height = Int(args[4]),
      let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
      ), let context = NSGraphicsContext(bitmapImageRep: bitmap)
else { fatalError("Usage: render input.svg output.png width height") }

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high
source.draw(in: NSRect(x: 0, y: 0, width: width, height: height))
NSGraphicsContext.restoreGraphicsState()
guard let png = bitmap.representation(using: .png, properties: [:])
else { fatalError("PNG encoding failed") }
try png.write(to: URL(fileURLWithPath: args[2]))
