#!/usr/bin/env swift

// Renders the Spacetrucker Galactic app icon as a 1024x1024 PNG.
//
// Vaporwave design:
//   - Cosmic gradient: black → deep purple → twilight purple → magenta tint
//   - Vaporwave sun: hot pink + magenta + gold gradient disc with three
//     horizontal stripe cutouts (iconic vaporwave sun)
//   - Glowing neon-cyan horizon line
//   - Perspective grid (pink) receding to the vanishing point under the sun
//   - Crescent moon in pale cyan, top-right
//   - Scattered neon-white stars across the upper sky
//
// Re-run after design tweaks. Output is deterministic.

import AppKit
import CoreGraphics
import Foundation

let size: CGFloat = 1024
let outputDefault = "StatusGalactic/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : outputDefault

// App Store icons must be opaque (no alpha channel). Use noneSkipLast
// (32-bit RGBX) so the encoded PNG has no alpha channel — Apple's
// "ITMS-90717 Invalid App Store Icon" rejection fires when alpha is
// present.
guard let context = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    fputs("error: failed to create CGContext\n", stderr)
    exit(1)
}

// Paint the canvas opaque before drawing anything else so even where
// the artwork doesn't cover, the icon is solid rather than transparent.
context.setFillColor(CGColor(red: 10/255, green: 0/255, blue: 20/255, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: size, height: size))

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(red: r/255, green: g/255, blue: b/255, alpha: a)
}

// MARK: - Background gradient (full square, no rounding)
// App Store guidelines: the asset must be a flat square. iOS applies
// the mask at install time. Submitting an already-rounded icon
// triggers ITMS-90022 / ITMS-90713.

let skyGradient = NSGradient(colors: [
    color(10, 0, 20),           // cosmic black (top)
    color(38, 8, 70),           // deep purple
    color(72, 20, 115),         // twilight purple
    color(140, 32, 130),        // magenta tint near horizon
])!
skyGradient.draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: 90)

// MARK: - Horizon line

let horizonY = size * 0.34

// MARK: - Perspective grid below horizon

let gridColor = color(255, 41, 200, 0.7) // neon magenta-pink
gridColor.setStroke()

let vanishingX = size * 0.5
let vanishingY = horizonY
let gridFar = horizonY
let gridNear: CGFloat = 0

// Radial lines (perspective)
let radialCount = 11
for i in 0...radialCount {
    let t = CGFloat(i) / CGFloat(radialCount)
    let nearX = t * size
    let path = NSBezierPath()
    path.move(to: NSPoint(x: nearX, y: gridNear))
    path.line(to: NSPoint(x: vanishingX, y: vanishingY))
    path.lineWidth = 1.5
    path.stroke()
}

// Horizontal lines (receding, denser near horizon)
let horizCount = 7
for i in 1...horizCount {
    let t = CGFloat(i) / CGFloat(horizCount + 1)
    // exponential easing makes lines denser toward the horizon
    let eased = pow(t, 2.2)
    let y = gridNear + eased * (gridFar - gridNear)
    let alpha = 0.30 + 0.55 * (1 - t) // more opaque close, faded far
    color(255, 41, 200, alpha).setStroke()
    let path = NSBezierPath()
    path.move(to: NSPoint(x: 0, y: y))
    path.line(to: NSPoint(x: size, y: y))
    path.lineWidth = 1.2
    path.stroke()
}

// MARK: - Neon horizon glow line

let horizonGlowGradient = NSGradient(colors: [
    color(0, 240, 255, 0.0),
    color(0, 240, 255, 0.9),
    color(0, 240, 255, 0.0),
])!
horizonGlowGradient.draw(in: NSRect(x: 0, y: horizonY - 6, width: size, height: 12), angle: 0)

color(0, 240, 255, 0.95).setFill()
NSRect(x: 0, y: horizonY - 1, width: size, height: 2).fill()

// MARK: - Vaporwave sun with horizontal stripe cutouts

let sunCenter = NSPoint(x: size * 0.5, y: horizonY + size * 0.02)
let sunRadius = size * 0.26

// Sun disc gradient (gold → pink → magenta, top to bottom)
let sunRect = NSRect(
    x: sunCenter.x - sunRadius,
    y: sunCenter.y - sunRadius,
    width: sunRadius * 2,
    height: sunRadius * 2
)
let sunPath = NSBezierPath(ovalIn: sunRect)
NSGraphicsContext.saveGraphicsState()
sunPath.addClip()

let sunGradient = NSGradient(colors: [
    color(255, 220, 130),       // gold (top of sun)
    color(255, 130, 110),       // peach
    color(255, 65, 175),        // hot pink
    color(255, 41, 200),        // neon magenta (bottom)
])!
sunGradient.draw(in: sunRect, angle: -90)

// Three horizontal stripe cutouts near the bottom — iconic vaporwave sun
let stripeColor = color(20, 5, 35)  // matches the deep gradient under it
stripeColor.setFill()
let stripeStarts: [CGFloat] = [0.05, 0.20, 0.36]  // fractions from bottom of sun
let stripeHeights: [CGFloat] = [0.05, 0.04, 0.03]
for (start, h) in zip(stripeStarts, stripeHeights) {
    let y = sunRect.minY + sunRect.height * start
    NSRect(x: sunRect.minX, y: y, width: sunRect.width, height: sunRect.height * h).fill()
}

NSGraphicsContext.restoreGraphicsState()

// Sun outer glow ring
color(255, 65, 175, 0.45).setStroke()
let sunGlow = NSBezierPath(ovalIn: sunRect.insetBy(dx: -10, dy: -10))
sunGlow.lineWidth = size * 0.018
sunGlow.stroke()

color(255, 65, 175, 0.20).setStroke()
let sunGlow2 = NSBezierPath(ovalIn: sunRect.insetBy(dx: -28, dy: -28))
sunGlow2.lineWidth = size * 0.030
sunGlow2.stroke()

// MARK: - Crescent moon (top right)

let moonCenter = NSPoint(x: size * 0.78, y: size * 0.80)
let moonRadius = size * 0.075

// Full disc (pale cyan)
color(220, 245, 255).setFill()
NSBezierPath(ovalIn: NSRect(
    x: moonCenter.x - moonRadius,
    y: moonCenter.y - moonRadius,
    width: moonRadius * 2,
    height: moonRadius * 2
)).fill()

// Crescent cutout
let cutoutCenter = NSPoint(x: moonCenter.x + moonRadius * 0.55, y: moonCenter.y + moonRadius * 0.05)
color(20, 5, 35).setFill()
NSBezierPath(ovalIn: NSRect(
    x: cutoutCenter.x - moonRadius,
    y: cutoutCenter.y - moonRadius,
    width: moonRadius * 2,
    height: moonRadius * 2
)).fill()

// Moon glow
color(0, 240, 255, 0.35).setStroke()
let moonGlow = NSBezierPath(ovalIn: NSRect(
    x: moonCenter.x - moonRadius * 1.25,
    y: moonCenter.y - moonRadius * 1.25,
    width: moonRadius * 2.5,
    height: moonRadius * 2.5
))
moonGlow.lineWidth = size * 0.010
moonGlow.stroke()

// MARK: - Stars

func drawStar(at p: NSPoint, radius r: CGFloat, alpha a: CGFloat = 1) {
    let path = NSBezierPath()
    let points = 4
    for i in 0..<(points * 2) {
        let angle = (CGFloat.pi / CGFloat(points)) * CGFloat(i) - .pi / 2
        let rr = (i % 2 == 0) ? r : r * 0.30
        let pp = NSPoint(x: p.x + cos(angle) * rr, y: p.y + sin(angle) * rr)
        if i == 0 { path.move(to: pp) } else { path.line(to: pp) }
    }
    path.close()
    color(255, 255, 255, a).setFill()
    path.fill()
}

let stars: [(NSPoint, CGFloat, CGFloat)] = [
    (NSPoint(x: size * 0.12, y: size * 0.85), size * 0.024, 1.00),
    (NSPoint(x: size * 0.28, y: size * 0.70), size * 0.014, 0.75),
    (NSPoint(x: size * 0.42, y: size * 0.92), size * 0.018, 0.90),
    (NSPoint(x: size * 0.58, y: size * 0.84), size * 0.012, 0.65),
    (NSPoint(x: size * 0.86, y: size * 0.62), size * 0.020, 0.85),
    (NSPoint(x: size * 0.92, y: size * 0.92), size * 0.016, 0.75),
    (NSPoint(x: size * 0.18, y: size * 0.55), size * 0.010, 0.60),
]
for (p, r, a) in stars {
    drawStar(at: p, radius: r, alpha: a)
}

// MARK: - Export

NSGraphicsContext.restoreGraphicsState()

guard let cgImage = context.makeImage() else {
    fputs("error: failed to make CGImage\n", stderr)
    exit(1)
}
let rep = NSBitmapImageRep(cgImage: cgImage)
guard let pngData = rep.representation(using: .png, properties: [:]) else {
    fputs("error: failed to encode PNG\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: outputPath)
try? FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)

do {
    try pngData.write(to: outputURL)
    print("wrote \(Int(size))x\(Int(size)) icon to \(outputPath)")
} catch {
    fputs("error: \(error)\n", stderr)
    exit(1)
}
