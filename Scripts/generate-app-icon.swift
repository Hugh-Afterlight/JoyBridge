#!/usr/bin/env swift

import AppKit
import Foundation

let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
let repoRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let iconSetURL = repoRoot
    .appendingPathComponent("JoyBridge")
    .appendingPathComponent("Assets.xcassets")
    .appendingPathComponent("AppIcon.appiconset")

let fileManager = FileManager.default
try fileManager.createDirectory(at: iconSetURL, withIntermediateDirectories: true)

struct IconSlot {
    let size: Int
    let scale: Int

    var pixels: Int {
        size * scale
    }

    var filename: String {
        scale == 1 ? "AppIcon-\(size).png" : "AppIcon-\(size)@\(scale)x.png"
    }
}

let slots = [
    IconSlot(size: 16, scale: 1),
    IconSlot(size: 16, scale: 2),
    IconSlot(size: 32, scale: 1),
    IconSlot(size: 32, scale: 2),
    IconSlot(size: 128, scale: 1),
    IconSlot(size: 128, scale: 2),
    IconSlot(size: 256, scale: 1),
    IconSlot(size: 256, scale: 2),
    IconSlot(size: 512, scale: 1),
    IconSlot(size: 512, scale: 2)
]

func drawIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    rect.fill()

    let cornerRadius = CGFloat(size) * 0.22
    let background = NSBezierPath(roundedRect: rect.insetBy(dx: CGFloat(size) * 0.04, dy: CGFloat(size) * 0.04), xRadius: cornerRadius, yRadius: cornerRadius)
    NSColor(calibratedRed: 0.06, green: 0.10, blue: 0.12, alpha: 1).setFill()
    background.fill()

    let topGlow = NSBezierPath(roundedRect: rect.insetBy(dx: CGFloat(size) * 0.08, dy: CGFloat(size) * 0.08), xRadius: cornerRadius * 0.78, yRadius: cornerRadius * 0.78)
    NSColor(calibratedRed: 0.14, green: 0.22, blue: 0.24, alpha: 1).setStroke()
    topGlow.lineWidth = max(1, CGFloat(size) * 0.018)
    topGlow.stroke()

    let bridgeLineWidth = max(2, CGFloat(size) * 0.055)
    let bridge = NSBezierPath()
    bridge.move(to: NSPoint(x: CGFloat(size) * 0.28, y: CGFloat(size) * 0.58))
    bridge.curve(
        to: NSPoint(x: CGFloat(size) * 0.72, y: CGFloat(size) * 0.58),
        controlPoint1: NSPoint(x: CGFloat(size) * 0.40, y: CGFloat(size) * 0.74),
        controlPoint2: NSPoint(x: CGFloat(size) * 0.60, y: CGFloat(size) * 0.74)
    )
    NSColor(calibratedRed: 0.31, green: 0.85, blue: 0.56, alpha: 1).setStroke()
    bridge.lineWidth = bridgeLineWidth
    bridge.lineCapStyle = .round
    bridge.stroke()

    let leftRect = NSRect(
        x: CGFloat(size) * 0.17,
        y: CGFloat(size) * 0.28,
        width: CGFloat(size) * 0.25,
        height: CGFloat(size) * 0.48
    )
    let rightRect = NSRect(
        x: CGFloat(size) * 0.58,
        y: CGFloat(size) * 0.28,
        width: CGFloat(size) * 0.25,
        height: CGFloat(size) * 0.48
    )

    let controllerRadius = CGFloat(size) * 0.115
    let leftController = NSBezierPath(roundedRect: leftRect, xRadius: controllerRadius, yRadius: controllerRadius)
    NSColor(calibratedRed: 0.16, green: 0.55, blue: 0.95, alpha: 1).setFill()
    leftController.fill()

    let rightController = NSBezierPath(roundedRect: rightRect, xRadius: controllerRadius, yRadius: controllerRadius)
    NSColor(calibratedRed: 0.96, green: 0.22, blue: 0.31, alpha: 1).setFill()
    rightController.fill()

    let keySize = CGFloat(size) * 0.105
    let keyGap = CGFloat(size) * 0.032
    let keyStartX = CGFloat(size) * 0.41
    let keyY = CGFloat(size) * 0.31
    for index in 0..<3 {
        let keyRect = NSRect(
            x: keyStartX + CGFloat(index) * (keySize + keyGap),
            y: keyY,
            width: keySize,
            height: keySize
        )
        let key = NSBezierPath(roundedRect: keyRect, xRadius: CGFloat(size) * 0.018, yRadius: CGFloat(size) * 0.018)
        NSColor(calibratedRed: 0.88, green: 0.93, blue: 0.92, alpha: 1).setFill()
        key.fill()
    }

    let leftStick = NSBezierPath(ovalIn: NSRect(
        x: CGFloat(size) * 0.245,
        y: CGFloat(size) * 0.57,
        width: CGFloat(size) * 0.09,
        height: CGFloat(size) * 0.09
    ))
    NSColor(calibratedWhite: 0.08, alpha: 0.88).setFill()
    leftStick.fill()

    let buttonRadius = CGFloat(size) * 0.033
    for (x, y) in [
        (CGFloat(0.665), CGFloat(0.61)),
        (CGFloat(0.735), CGFloat(0.61)),
        (CGFloat(0.70), CGFloat(0.675)),
        (CGFloat(0.70), CGFloat(0.545))
    ] {
        let button = NSBezierPath(ovalIn: NSRect(
            x: CGFloat(size) * x,
            y: CGFloat(size) * y,
            width: buttonRadius * CGFloat(2),
            height: buttonRadius * CGFloat(2)
        ))
        NSColor(calibratedWhite: 0.08, alpha: 0.88).setFill()
        button.fill()
    }

    return image
}

func writePNG(_ image: NSImage, to url: URL, pixels: Int) throws {
    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "JoyBridgeIconGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to render \(pixels)x\(pixels) PNG"])
    }

    try pngData.write(to: url, options: .atomic)
}

for slot in slots {
    let image = drawIcon(size: slot.pixels)
    try writePNG(image, to: iconSetURL.appendingPathComponent(slot.filename), pixels: slot.pixels)
    print("Generated \(slot.filename)")
}

let imagesJSON = slots.map { slot -> [String: String] in
    [
        "filename": slot.filename,
        "idiom": "mac",
        "scale": "\(slot.scale)x",
        "size": "\(slot.size)x\(slot.size)"
    ]
}

let contents: [String: Any] = [
    "images": imagesJSON,
    "info": [
        "author": "xcode",
        "version": 1
    ]
]

let jsonData = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try jsonData.write(to: iconSetURL.appendingPathComponent("Contents.json"), options: .atomic)
print("Updated \(iconSetURL.path)/Contents.json")
