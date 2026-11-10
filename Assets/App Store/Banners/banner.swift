#!/usr/bin/env swift

// Draws the App Store header and search results banners: the app icon's scene opened
// up, with Tokyo Big Sight dreaming a soft cloud that carries the app's name, centred.
// Usage: ./banner.swift    (writes en/ and ja/ Header.png and Search Results.png next to this script)

import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

let skyTop = rgb(0.40, 0.60, 0.94)
let skyHorizon = rgb(0.80, 0.90, 0.99)
let ink = rgb(0.38, 0.52, 0.93)
let shade = rgb(0.84, 0.90, 1.0)

/// Tokyo Big Sight as on the icon, in its artwork's 1024 space (y down), standing on y = 1024.
let bigSightFaces: [[CGPoint]] = [
    [(146, 702), (938, 702), (757, 901), (678, 901), (540, 724), (500, 768), (380, 901), (300, 901)],
    [(278, 901), (395, 901), (395, 1024), (278, 1024)],
    [(655, 901), (773, 901), (773, 1024), (655, 1024)],
].map { $0.map { CGPoint(x: $0.0, y: $0.1) } }
let bigSightShades: [[CGPoint]] = [
    [(86, 728), (146, 702), (300, 901), (246, 901)],
    [(500, 768), (540, 724), (678, 901), (624, 901)],
    [(242, 901), (278, 901), (278, 1024), (242, 1024)],
    [(620, 901), (655, 901), (655, 1024), (620, 1024)],
].map { $0.map { CGPoint(x: $0.0, y: $0.1) } }

struct Banner {
    let name: String
    let language: String
    let width: CGFloat
    let height: CGFloat
}

/// Draws in a top-left space, y down, so the layout reads like the artwork it comes from.
func render(_ banner: Banner) {
    let w = banner.width, h = banner.height
    guard let context = CGContext(
        data: nil, width: Int(w), height: Int(h), bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { fatalError() }
    context.translateBy(x: 0, y: h)
    context.scaleBy(x: 1, y: -1)

    let sky = CGGradient(colorsSpace: nil, colors: [skyTop, skyHorizon] as CFArray, locations: [0, 1])!
    context.drawLinearGradient(sky, start: .zero, end: CGPoint(x: 0, y: h), options: [])

    // Distant clouds on either side, paler and smaller, so the wide banner is not empty.
    let unit = min(w, h * 2.33)
    for (x, y, size, alpha, seed) in [
        (0.07, 0.22, 0.24, 0.75, 11), (0.10, 0.76, 0.11, 0.55, 23), (0.93, 0.20, 0.21, 0.7, 37), (0.90, 0.78, 0.10, 0.5, 41),
    ] as [(CGFloat, CGFloat, CGFloat, CGFloat, UInt64)] {
        cloud(at: CGPoint(x: w * x, y: h * y), width: unit * size, alpha: alpha, seed: seed, in: context)
    }

    // The dream: a broad cloud filling the middle of the banner, behind Big Sight.
    let center = CGPoint(x: w / 2, y: h / 2)
    let nameWidth = min(w * 0.26, h * 0.45)
    // Raised a little above the name, clear of Big Sight's roof.
    let cloudWidth = min(w * 0.63, h * 1.17)
    cloud(at: CGPoint(x: center.x, y: center.y), width: cloudWidth, alpha: 1, seed: 7, puffs: 160, isRound: true, in: context)

    // Big Sight in front, its pillars running off the bottom edge as on the icon.
    let siteHeight = min(h * 0.27, w * 0.15)
    let scale = siteHeight / 322
    let site = CGAffineTransform(translationX: w / 2 - 512 * scale, y: h - 1024 * scale).scaledBy(x: scale, y: scale)
    for (faces, color) in [(bigSightFaces, rgb(1, 1, 1)), (bigSightShades, shade)] {
        for face in faces {
            context.addLines(between: face.map { $0.applying(site) })
            context.closePath()
        }
        context.setFillColor(color)
        context.fillPath()
    }

    name(at: center, width: nameWidth, language: banner.language, in: context)

    let url = scriptDir.appendingPathComponent("\(banner.language)/\(banner.name).png")
    guard let image = context.makeImage(),
          let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { fatalError() }
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
    print("wrote \(banner.language)/\(banner.name).png")
}

/// A small, repeatable random source, so every run draws the same clouds.
struct Random {
    var state: UInt64
    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat(state >> 33) / CGFloat(1 << 31)
    }
}

/// A soft cumulus: feathered puffs heaped into a dome over a flatter base, white on top
/// and shading to a pale blue-grey underneath. Returns the area it covers.
@discardableResult
func cloud(at center: CGPoint, width: CGFloat, alpha: CGFloat, seed: UInt64, puffs count: Int = 110, isRound: Bool = false, in context: CGContext) -> CGRect {
    var random = Random(state: seed &* 2654435761 &+ 1)
    var puffs: [(CGPoint, CGFloat)] = []
    for index in 0..<count {
        // The first few lie along the base, so the cloud has a body under its dome.
        let t = index < count / 4 ? CGFloat(index) / CGFloat(max(count / 4 - 1, 1)) * 2 - 1 : random.next() * 2 - 1
        let dome = width * 0.3 * sqrt(max(0, 1 - t * t))
        let lift = index < count / 4 ? 0 : pow(random.next(), 0.8) * dome
        let radius = width * (0.065 + 0.07 * pow(random.next(), 2)) * (1 - 0.4 * abs(t))
        if isRound {
            // Spread through an ellipse, larger towards the middle, so no edge is heavier.
            let angle = random.next() * 2 * .pi
            let reach = sqrt(random.next())
            let size = width * (0.07 + 0.06 * pow(random.next(), 2)) * (1.25 - 0.5 * reach)
            puffs.append((CGPoint(x: cos(angle) * reach * width * 0.34, y: sin(angle) * reach * width * 0.17), size))
        } else {
            puffs.append((CGPoint(x: t * width * 0.4, y: -lift), radius))
        }
    }
    // Measured where the feathered puffs are still mostly opaque, so the visible cloud is what gets centred.
    let body: CGFloat = isRound ? 0.6 : 1
    let minX = puffs.map { $0.0.x - $0.1 * body }.min()!, maxX = puffs.map { $0.0.x + $0.1 * body }.max()!
    let minY = puffs.map { $0.0.y - $0.1 * body }.min()!, maxY = puffs.map { $0.0.y + $0.1 * (isRound ? body : 0.7) }.max()!
    let shift = CGPoint(x: center.x - (minX + maxX) / 2, y: center.y - (minY + maxY) / 2)
    let bounds = CGRect(x: minX + shift.x, y: minY + shift.y, width: maxX - minX, height: maxY - minY)

    let feather = CGGradient(colorsSpace: nil, colors: [rgb(1, 1, 1, 1), rgb(1, 1, 1, 0.85), rgb(1, 1, 1, 0.35), rgb(1, 1, 1, 0)] as CFArray,
                             locations: [0, 0.4, 0.75, 1])!
    context.saveGState()
    context.setAlpha(alpha)
    context.beginTransparencyLayer(auxiliaryInfo: nil)
    for (point, radius) in puffs {
        let p = CGPoint(x: point.x + shift.x, y: point.y + shift.y)
        context.drawRadialGradient(feather, startCenter: p, startRadius: 0, endCenter: p, endRadius: radius, options: [])
    }
    // Light from above: the underside takes on the sky's shadowed blue.
    context.setBlendMode(.sourceAtop)
    let underside = CGGradient(colorsSpace: nil, colors: [rgb(1, 1, 1, 0), rgb(0.80, 0.86, 0.97, 1)] as CFArray, locations: [0, 1])!
    context.drawLinearGradient(underside, start: CGPoint(x: 0, y: bounds.minY + bounds.height * 0.45),
                               end: CGPoint(x: 0, y: bounds.maxY), options: [.drawsAfterEndLocation])
    context.endTransparencyLayer()
    context.restoreGState()
    return bounds
}

/// One line in the icon's blue, sized to span `width`.
func fitted(_ text: String, font name: String, width: CGFloat) -> CTLine {
    func line(_ size: CGFloat) -> CTLine {
        let attributes = [
            kCTFontAttributeName: CTFontCreateWithName(name as CFString, size, nil),
            kCTForegroundColorAttributeName: ink, kCTKernAttributeName: size * 0.02,
        ] as CFDictionary
        return CTLineCreateWithAttributedString(CFAttributedStringCreate(nil, text as CFString, attributes)!)
    }
    return line(100 * width / CTLineGetTypographicBounds(line(100), nil, nil, nil))
}

/// Draws a line with its glyphs' bounds centred on `center`.
func draw(_ line: CTLine, centredAt center: CGPoint, in context: CGContext) {
    let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    context.saveGState()
    context.translateBy(x: center.x - bounds.midX, y: center.y + bounds.midY)
    context.scaleBy(x: 1, y: -1)
    context.textPosition = .zero
    CTLineDraw(line, context)
    context.restoreGState()
}

/// The app's name, centred on `center`: in English alone, or in Japanese as the katakana
/// name under a smaller English one, the pair centred together.
func name(at center: CGPoint, width: CGFloat, language: String, in context: CGContext) {
    let english = "CiRCLES"
    guard language == "ja" else {
        draw(fitted(english, font: "HelveticaNeue-Bold", width: width), centredAt: center, in: context)
        return
    }
    let small = fitted(english, font: "HelveticaNeue-Bold", width: width * 0.4)
    let large = fitted("サークルズ", font: "HiraginoSans-W7", width: width * 0.95)
    let smallHeight = CTLineGetBoundsWithOptions(small, .useGlyphPathBounds).height
    let largeHeight = CTLineGetBoundsWithOptions(large, .useGlyphPathBounds).height
    let gap = smallHeight * 0.5
    let top = center.y - (smallHeight + gap + largeHeight) / 2
    draw(small, centredAt: CGPoint(x: center.x, y: top + smallHeight / 2), in: context)
    draw(large, centredAt: CGPoint(x: center.x, y: top + smallHeight + gap + largeHeight / 2), in: context)
}

for language in ["en", "ja"] {
    try? FileManager.default.createDirectory(at: scriptDir.appendingPathComponent(language), withIntermediateDirectories: true)
    render(Banner(name: "Header", language: language, width: 3840, height: 1646))
    render(Banner(name: "Search Results", language: language, width: 3840, height: 2560))
}
