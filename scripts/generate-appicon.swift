// Regenerates every PNG in Weiki's AppIcon.appiconset: an amber cup, saucer, and steam
// on a deep-navy rounded square ("Night shift"). The cup is drawn with paths because
// SF Symbols may not be used in app icons.
//
// Run from the repo root: make icon (or: xcrun swift scripts/generate-appicon.swift)
import AppKit
import ImageIO
import UniformTypeIdentifiers

// MARK: - Output set (matches Contents.json)

let outputs: [(name: String, px: Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]

let appiconsetPath = "Weiki/Assets.xcassets/AppIcon.appiconset"

// MARK: - Colors

let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

let backgroundGradient = CGGradient(colorsSpace: srgb,
                                    colors: [color(0x2E3F6E), color(0x121930)] as CFArray,
                                    locations: [0, 1])!
let cupColor = color(0xF6B94C)
let steamColor = color(0xFFFFFF, 0.6)

// MARK: - Shapes (100-unit design space, y-down)

/// A cup that narrows toward its base.
func cupBody() -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 29, y: 43))
    path.addLine(to: CGPoint(x: 67, y: 43))
    path.addCurve(to: CGPoint(x: 58, y: 71), control1: CGPoint(x: 67, y: 58), control2: CGPoint(x: 64, y: 69))
    path.addLine(to: CGPoint(x: 38, y: 71))
    path.addCurve(to: CGPoint(x: 29, y: 43), control1: CGPoint(x: 32, y: 69), control2: CGPoint(x: 29, y: 58))
    path.closeSubpath()
    return path
}

/// A half ring on the cup's right side.
func handle() -> CGPath {
    let path = CGMutablePath()
    path.addArc(center: CGPoint(x: 67, y: 53), radius: 7.5, startAngle: -.pi / 2, endAngle: .pi / 2, clockwise: false)
    return path.copy(strokingWithWidth: 4.5, lineCap: .round, lineJoin: .round, miterLimit: 10)
}

func saucer() -> CGPath {
    CGPath(roundedRect: CGRect(x: 22, y: 73, width: 52, height: 5.5), cornerWidth: 2.75, cornerHeight: 2.75, transform: nil)
}

/// Three S-shaped wisps of steam above the cup.
func steam(width: CGFloat) -> CGPath {
    let path = CGMutablePath()
    for x in [39, 48, 57] as [CGFloat] {
        path.move(to: CGPoint(x: x, y: 37))
        path.addCurve(to: CGPoint(x: x, y: 21), control1: CGPoint(x: x - 5, y: 32), control2: CGPoint(x: x + 5, y: 26))
    }
    return path.copy(strokingWithWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 10)
}

// MARK: - Render

func renderIcon(px: Int) -> CGImage {
    let ctx = CGContext(data: nil, width: px, height: px,
                        bitsPerComponent: 8, bytesPerRow: 0, space: srgb,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    // Flip so the 100-unit design space is y-down.
    ctx.translateBy(x: 0, y: CGFloat(px))
    ctx.scaleBy(x: CGFloat(px) / 100, y: -CGFloat(px) / 100)
    ctx.setAllowsAntialiasing(true)

    // Background rounded square (82% of the canvas) with a vertical gradient.
    let square = CGPath(roundedRect: CGRect(x: 9, y: 9, width: 82, height: 82),
                        cornerWidth: 19, cornerHeight: 19, transform: nil)
    ctx.saveGState()
    ctx.addPath(square)
    ctx.clip()
    ctx.drawLinearGradient(backgroundGradient, start: CGPoint(x: 50, y: 9), end: CGPoint(x: 50, y: 91), options: [])
    ctx.restoreGState()

    // Thicker steam at 16 and 32 px, where the thin wisps would disappear.
    ctx.setFillColor(steamColor)
    ctx.addPath(steam(width: px <= 32 ? 5.5 : 3.6))
    ctx.fillPath()

    ctx.setFillColor(cupColor)
    for shape in [cupBody(), handle(), saucer()] {
        ctx.addPath(shape)
        ctx.fillPath()
    }
    return ctx.makeImage()!
}

// MARK: - Main

guard FileManager.default.fileExists(atPath: appiconsetPath) else {
    fputs("error: \(appiconsetPath) not found — run from the repo root\n", stderr)
    exit(1)
}

for (name, px) in outputs {
    let url = URL(fileURLWithPath: "\(appiconsetPath)/\(name)")
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fputs("error: cannot create \(url.path)\n", stderr)
        exit(1)
    }
    CGImageDestinationAddImage(destination, renderIcon(px: px), nil)
    guard CGImageDestinationFinalize(destination) else {
        fputs("error: failed writing \(url.path)\n", stderr)
        exit(1)
    }
    print("wrote \(name) (\(px)x\(px))")
}
print("done — \(outputs.count) PNGs regenerated")
