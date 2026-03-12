import AppKit

struct IconSpec {
    let filename: String
    let points: CGFloat
    let scale: CGFloat

    var pixels: Int {
        Int(points * scale)
    }
}

let iconSpecs: [IconSpec] = [
    .init(filename: "iphone-20@2x.png", points: 20, scale: 2),
    .init(filename: "iphone-20@3x.png", points: 20, scale: 3),
    .init(filename: "iphone-29@2x.png", points: 29, scale: 2),
    .init(filename: "iphone-29@3x.png", points: 29, scale: 3),
    .init(filename: "iphone-40@2x.png", points: 40, scale: 2),
    .init(filename: "iphone-40@3x.png", points: 40, scale: 3),
    .init(filename: "iphone-60@2x.png", points: 60, scale: 2),
    .init(filename: "iphone-60@3x.png", points: 60, scale: 3),
    .init(filename: "ipad-20@1x.png", points: 20, scale: 1),
    .init(filename: "ipad-20@2x.png", points: 20, scale: 2),
    .init(filename: "ipad-29@1x.png", points: 29, scale: 1),
    .init(filename: "ipad-29@2x.png", points: 29, scale: 2),
    .init(filename: "ipad-40@1x.png", points: 40, scale: 1),
    .init(filename: "ipad-40@2x.png", points: 40, scale: 2),
    .init(filename: "ipad-76@1x.png", points: 76, scale: 1),
    .init(filename: "ipad-76@2x.png", points: 76, scale: 2),
    .init(filename: "ipad-83.5@2x.png", points: 83.5, scale: 2),
    .init(filename: "ios-marketing-1024@1x.png", points: 1024, scale: 1),
    .init(filename: "mac-16@1x.png", points: 16, scale: 1),
    .init(filename: "mac-16@2x.png", points: 16, scale: 2),
    .init(filename: "mac-32@1x.png", points: 32, scale: 1),
    .init(filename: "mac-32@2x.png", points: 32, scale: 2),
    .init(filename: "mac-128@1x.png", points: 128, scale: 1),
    .init(filename: "mac-128@2x.png", points: 128, scale: 2),
    .init(filename: "mac-256@1x.png", points: 256, scale: 1),
    .init(filename: "mac-256@2x.png", points: 256, scale: 2),
    .init(filename: "mac-512@1x.png", points: 512, scale: 1),
    .init(filename: "mac-512@2x.png", points: 512, scale: 2),
]

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: swift GenerateAppIcon.swift <output-directory>\n", stderr)
    exit(1)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let fileManager = FileManager.default

try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for spec in iconSpecs {
    let image = NSImage(size: NSSize(width: spec.pixels, height: spec.pixels))
    image.lockFocus()

    let canvas = NSRect(x: 0, y: 0, width: spec.pixels, height: spec.pixels)
    NSColor(calibratedWhite: 0.965, alpha: 1).setFill()
    canvas.fill()

    drawShadowLayer(in: canvas)
    drawPaperLayer(in: canvas)

    image.unlockFocus()

    guard let tiffData = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiffData),
          let pngData = rep.representation(using: .png, properties: [:]) else {
        fputs("Failed to render \(spec.filename)\n", stderr)
        exit(1)
    }

    try pngData.write(to: outputDirectory.appendingPathComponent(spec.filename))
}

func drawShadowLayer(in canvas: NSRect) {
    let width = canvas.width
    let height = canvas.height

    let rect = NSRect(
        x: width * 0.30,
        y: height * 0.29,
        width: width * 0.48,
        height: height * 0.44
    )

    let path = NSBezierPath(roundedRect: rect, xRadius: width * 0.06, yRadius: width * 0.06)
    var transform = AffineTransform()
    transform.translate(x: width * 0.03, y: -height * 0.01)
    transform.rotate(byDegrees: -6)
    path.transform(using: transform)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowBlurRadius = width * 0.055
    shadow.shadowOffset = NSSize(width: width * 0.012, height: -height * 0.02)
    shadow.shadowColor = NSColor(calibratedWhite: 0.2, alpha: 0.26)
    shadow.set()

    let gradient = NSGradient(colors: [
        NSColor(calibratedWhite: 0.42, alpha: 0.95),
        NSColor(calibratedWhite: 0.20, alpha: 0.98)
    ])!
    gradient.draw(in: path, angle: -72)
    NSGraphicsContext.restoreGraphicsState()
}

func drawPaperLayer(in canvas: NSRect) {
    let width = canvas.width
    let height = canvas.height

    let rect = NSRect(
        x: width * 0.26,
        y: height * 0.36,
        width: width * 0.44,
        height: height * 0.40
    )

    let path = NSBezierPath(roundedRect: rect, xRadius: width * 0.055, yRadius: width * 0.055)
    var transform = AffineTransform()
    transform.rotate(byDegrees: -8)
    path.transform(using: transform)

    let curl = NSBezierPath()
    curl.move(to: NSPoint(x: rect.minX + width * 0.01, y: rect.minY + height * 0.025))
    curl.curve(
        to: NSPoint(x: rect.maxX - width * 0.04, y: rect.minY + height * 0.02),
        controlPoint1: NSPoint(x: rect.minX + width * 0.11, y: rect.minY - height * 0.01),
        controlPoint2: NSPoint(x: rect.maxX - width * 0.15, y: rect.minY - height * 0.015)
    )
    curl.curve(
        to: NSPoint(x: rect.maxX, y: rect.maxY - height * 0.03),
        controlPoint1: NSPoint(x: rect.maxX + width * 0.01, y: rect.minY + height * 0.07),
        controlPoint2: NSPoint(x: rect.maxX + width * 0.015, y: rect.maxY - height * 0.12)
    )
    curl.curve(
        to: NSPoint(x: rect.minX + width * 0.04, y: rect.maxY),
        controlPoint1: NSPoint(x: rect.maxX - width * 0.12, y: rect.maxY + height * 0.018),
        controlPoint2: NSPoint(x: rect.minX + width * 0.14, y: rect.maxY + height * 0.016)
    )
    curl.curve(
        to: NSPoint(x: rect.minX, y: rect.minY + height * 0.03),
        controlPoint1: NSPoint(x: rect.minX - width * 0.01, y: rect.maxY - height * 0.16),
        controlPoint2: NSPoint(x: rect.minX - width * 0.02, y: rect.minY + height * 0.12)
    )
    curl.close()
    curl.transform(using: transform)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowBlurRadius = width * 0.04
    shadow.shadowOffset = NSSize(width: 0, height: -height * 0.01)
    shadow.shadowColor = NSColor(calibratedWhite: 0.72, alpha: 0.22)
    shadow.set()

    let gradient = NSGradient(colors: [
        NSColor(calibratedWhite: 0.995, alpha: 1),
        NSColor(calibratedWhite: 0.94, alpha: 1)
    ])!
    gradient.draw(in: curl, angle: -82)

    NSColor(calibratedWhite: 1, alpha: 0.48).setStroke()
    curl.lineWidth = max(width * 0.0045, 1)
    curl.stroke()
    NSGraphicsContext.restoreGraphicsState()
}
