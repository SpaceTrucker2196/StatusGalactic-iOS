#!/usr/bin/env swift

// Renders the Status Galactic app icon to a 1024 x 1024 PNG.
//
// Usage:
//   ./scripts/render-icon.swift                      # writes to AppIcon.appiconset
//   ./scripts/render-icon.swift path/to/icon.png     # writes to a custom path
//
// Design:
//   - Deep night-sky gradient background (astronomical twilight palette)
//   - Sun arc rising/setting at the horizon (warm gold)
//   - Crescent moon (cream) tucked above the sun
//   - Three star points scattered in the upper half
//   - Subtle horizon line implying the twilight strip
//
// Re-run after design tweaks. The output is deterministic.

import AppKit
import CoreGraphics
import Foundation

let size: CGFloat = 1024
let outputDefault = "StatusGalactic/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : outputDefault

// MARK: - Bitmap context

guard let context = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("error: failed to create CGContext\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)

// MARK: - Helpers

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(red: r/255, green: g/255, blue: b/255, alpha: a)
}

let cornerRadius: CGFloat = size * 0.225   // matches iOS app-icon mask roughly

// MARK: - 1. Rounded background fill

let backgroundPath = NSBezierPath(
    roundedRect: NSRect(x: 0, y: 0, width: size, height: size),
    xRadius: cornerRadius,
    yRadius: cornerRadius
)
backgroundPath.addClip()

// Vertical gradient: deep navy at top, deep purple in middle, dark teal at bottom.
let gradient = NSGradient(colors: [
    color(10, 14, 35),        // top: astronomical dark
    color(28, 24, 78),        // upper-mid: deep night
    color(38, 60, 110),       // lower-mid: nautical twilight
    color(60, 90, 130),       // near horizon: civil twilight
])!
gradient.draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: 90)

// MARK: - 2. Horizon line (subtle)

let horizonY = size * 0.32
color(255, 255, 255, 0.10).setFill()
NSRect(x: 0, y: horizonY - 1, width: size, height: 2).fill()

// MARK: - 3. Sun arc rising at the horizon

let sunCenter = NSPoint(x: size * 0.34, y: horizonY)
let sunRadius = size * 0.22
let sunPath = NSBezierPath()
sunPath.move(to: NSPoint(x: sunCenter.x - sunRadius, y: sunCenter.y))
sunPath.appendArc(
    withCenter: sunCenter,
    radius: sunRadius,
    startAngle: 180,
    endAngle: 360,
    clockwise: true
)
sunPath.line(to: NSPoint(x: sunCenter.x - sunRadius, y: sunCenter.y))
sunPath.close()

// Sun is filled with a radial-style gradient (gold → orange)
let sunGradient = NSGradient(colors: [
    color(255, 215, 130),
    color(245, 175, 70),
    color(220, 130, 40),
])!
sunGradient.draw(in: sunPath, angle: -90)

// Soft glow ring around the sun
color(255, 200, 110, 0.18).setStroke()
let glow = NSBezierPath()
glow.appendArc(
    withCenter: sunCenter,
    radius: sunRadius * 1.10,
    startAngle: 180,
    endAngle: 360,
    clockwise: true
)
glow.lineWidth = size * 0.012
glow.stroke()

// MARK: - 4. Crescent moon

let moonCenter = NSPoint(x: size * 0.66, y: size * 0.72)
let moonRadius = size * 0.13

// Full disc (cream)
color(245, 240, 220).setFill()
NSBezierPath(ovalIn: NSRect(
    x: moonCenter.x - moonRadius,
    y: moonCenter.y - moonRadius,
    width: moonRadius * 2,
    height: moonRadius * 2
)).fill()

// Crescent cutout: a darker disc offset right
let cutoutCenter = NSPoint(x: moonCenter.x + moonRadius * 0.55, y: moonCenter.y)
color(20, 24, 60).setFill()
NSBezierPath(ovalIn: NSRect(
    x: cutoutCenter.x - moonRadius,
    y: cutoutCenter.y - moonRadius,
    width: moonRadius * 2,
    height: moonRadius * 2
)).fill()

// MARK: - 5. Scattered stars

func drawStar(at point: NSPoint, radius: CGFloat, alpha: CGFloat = 1) {
    let path = NSBezierPath()
    let points = 4
    for i in 0..<(points * 2) {
        let angle = (CGFloat.pi / CGFloat(points)) * CGFloat(i) - .pi / 2
        let r = (i % 2 == 0) ? radius : radius * 0.32
        let p = NSPoint(x: point.x + cos(angle) * r, y: point.y + sin(angle) * r)
        if i == 0 { path.move(to: p) } else { path.line(to: p) }
    }
    path.close()
    color(255, 245, 220, alpha).setFill()
    path.fill()
}

let stars: [(NSPoint, CGFloat, CGFloat)] = [
    (NSPoint(x: size * 0.18, y: size * 0.82), size * 0.024, 0.95),
    (NSPoint(x: size * 0.46, y: size * 0.86), size * 0.018, 0.80),
    (NSPoint(x: size * 0.82, y: size * 0.50), size * 0.020, 0.85),
    (NSPoint(x: size * 0.30, y: size * 0.62), size * 0.014, 0.65),
    (NSPoint(x: size * 0.88, y: size * 0.86), size * 0.016, 0.70),
]
for (point, r, alpha) in stars {
    drawStar(at: point, radius: r, alpha: alpha)
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
