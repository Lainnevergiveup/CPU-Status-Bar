import AppKit
import Foundation

let svgPath = "/Users/lain/Downloads/Status.svg"
let iconsetDir = "/tmp/AppIcon.iconset"

let fm = FileManager.default
try? fm.removeItem(atPath: iconsetDir)
try fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

guard let svgData = try? Data(contentsOf: URL(fileURLWithPath: svgPath)),
      let svgImage = NSImage(data: svgData) else {
    print("ERROR: Failed to load SVG from \(svgPath)")
    exit(1)
}

let sizes: [(Int, Int, String)] = [
    (16,  16,  "icon_16x16.png"),
    (32,  32,  "icon_16x16@2x.png"),
    (32,  32,  "icon_32x32.png"),
    (64,  64,  "icon_32x32@2x.png"),
    (128, 128, "icon_128x128.png"),
    (256, 256, "icon_128x128@2x.png"),
    (256, 256, "icon_256x256.png"),
    (512, 512, "icon_256x256@2x.png"),
    (512, 512, "icon_512x512.png"),
    (1024, 1024, "icon_512x512@2x.png"),
]

for (logicalW, actualW, name) in sizes {
    let size = NSSize(width: logicalW, height: logicalW)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: actualW,
        pixelsHigh: actualW,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = size

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    svgImage.draw(in: NSRect(origin: .zero, size: size),
                  from: .zero,
                  operation: .copy,
                  fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        print("ERROR: Failed to generate PNG for \(name)")
        exit(1)
    }
    try pngData.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(name)"))
}

print("Icons generated in \(iconsetDir)")
