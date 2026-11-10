#!/usr/bin/env swift

// Draws the App Store header and search results banners: the app icon's scene opened
// up, with Tokyo Big Sight dreaming a cloud that carries the app's name, centred.
// Usage: ./banner.swift    (writes Header.png and Search Results.png next to this script)

import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let fontURL = scriptDir.appendingPathComponent("../../ItcKabel Demi.ttf").standardizedFileURL
CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

let skyTop = rgb(0.40, 0.60, 0.94)
let skyHorizon = rgb(0.80, 0.90, 0.99)
let ink = rgb(0.38, 0.52, 0.93)
let shade = rgb(0.84, 0.90, 1.0)

/// The icon's cloud: overlapping circles, in a 1×0.58 box with its origin at the top left.
let cloudLobes: [(x: CGFloat, y: CGFloat, r: CGFloat)] = [
    (0.12, 0.28, 0.118), (0.36, 0.215, 0.18), (0.615, 0.158, 0.158), (0.875, 0.28, 0.125),
    (0.36, 0.43, 0.15), (0.65, 0.435, 0.145),
]

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
    for (x, y, size, alpha) in [
        (0.07, 0.24, 0.20, 0.5), (0.22, 0.70, 0.12, 0.35), (0.94, 0.20, 0.17, 0.45), (0.79, 0.72, 0.11, 0.35),
    ] as [(CGFloat, CGFloat, CGFloat, CGFloat)] {
        cloud(at: CGPoint(x: w * x, y: h * y), width: unit * size, alpha: alpha, in: context)
    }

    // The dream: a cloud in the middle of the banner.
    let cloudWidth = min(w * 0.42, h * 0.7)
    let center = CGPoint(x: w / 2, y: h / 2)
    let cloudBottom = center.y + cloudWidth * 0.29

    // Big Sight below it, its pillars running off the bottom edge as on the icon.
    let roof = cloudBottom + (h - cloudBottom) * 0.36
    let scale = (h - roof) / 322
    let site = CGAffineTransform(translationX: w / 2 - 512 * scale, y: h - 1024 * scale).scaledBy(x: scale, y: scale)
    for (faces, color) in [(bigSightFaces, rgb(1, 1, 1)), (bigSightShades, shade)] {
        for face in faces {
            context.addLines(between: face.map { $0.applying(site) })
            context.closePath()
        }
        context.setFillColor(color)
        context.fillPath()
    }

    cloud(at: center, width: cloudWidth, alpha: 1, in: context)
    // The thought bubbles, stepping down from the cloud toward the roof.
    for (t, r) in [(0.3, 0.04), (0.72, 0.026)] as [(CGFloat, CGFloat)] {
        let p = CGPoint(x: center.x + cloudWidth * (0.2 + 0.1 * t), y: cloudBottom + (roof - cloudBottom) * t)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: unit * 0.003), blur: unit * 0.01, color: rgb(0.15, 0.25, 0.6, 0.2))
        context.setFillColor(rgb(1, 1, 1))
        context.fillEllipse(in: CGRect(x: p.x - cloudWidth * r, y: p.y - cloudWidth * r, width: cloudWidth * r * 2, height: cloudWidth * r * 2))
        context.restoreGState()
    }

    name(at: center, width: cloudWidth * 0.62, in: context)

    let url = scriptDir.appendingPathComponent("\(banner.name).png")
    guard let image = context.makeImage(),
          let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { fatalError() }
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
    print("wrote \(banner.name).png")
}

func cloud(at center: CGPoint, width: CGFloat, alpha: CGFloat, in context: CGContext) {
    let height = width * 0.58
    let origin = CGPoint(x: center.x - width / 2, y: center.y - height / 2)
    let shape = CGMutablePath()
    for lobe in cloudLobes {
        shape.addEllipse(in: CGRect(x: origin.x + (lobe.x - lobe.r) * width, y: origin.y + lobe.y * width - lobe.r * width,
                                    width: lobe.r * 2 * width, height: lobe.r * 2 * width))
    }
    // The lobes' centres, joined, fill the middle so no sky shows between them.
    let order = [0, 1, 2, 3, 5, 4]
    shape.addLines(between: order.map { CGPoint(x: origin.x + cloudLobes[$0].x * width, y: origin.y + cloudLobes[$0].y * width) })
    shape.closeSubpath()
    context.saveGState()
    context.setAlpha(alpha)
    context.beginTransparencyLayer(auxiliaryInfo: nil)
    context.setShadow(offset: CGSize(width: 0, height: width * 0.02), blur: width * 0.06, color: rgb(0.15, 0.25, 0.6, 0.22))
    context.addPath(shape)
    context.setFillColor(rgb(1, 1, 1))
    context.fillPath()
    context.setShadow(offset: .zero, blur: 0, color: nil)
    // A faint blue underside, as on the icon's glass cloud.
    context.addPath(shape)
    context.clip()
    let underside = CGGradient(colorsSpace: nil, colors: [rgb(1, 1, 1, 0), rgb(0.86, 0.91, 1.0, 1)] as CFArray, locations: [0, 1])!
    context.drawLinearGradient(underside, start: CGPoint(x: 0, y: origin.y + height * 0.35),
                               end: CGPoint(x: 0, y: origin.y + height * 1.05), options: [])
    context.endTransparencyLayer()
    context.restoreGState()
}

/// The app's name in Kabel, the icon's blue, centred on `center` by its capital height.
func name(at center: CGPoint, width: CGFloat, in context: CGContext) {
    let probe = CTFontCreateWithName("ItcKabelDemi" as CFString, 100, nil)
    func line(_ font: CTFont) -> CTLine {
        let attributes = [kCTFontAttributeName: font, kCTForegroundColorAttributeName: ink, kCTKernAttributeName: 2] as CFDictionary
        return CTLineCreateWithAttributedString(CFAttributedStringCreate(nil, "CiRCLES" as CFString, attributes)!)
    }
    let size = 100 * width / CTLineGetTypographicBounds(line(probe), nil, nil, nil)
    let font = CTFontCreateWithName("ItcKabelDemi" as CFString, size, nil)
    let text = line(font)
    let bounds = CTLineGetBoundsWithOptions(text, .useGlyphPathBounds)
    context.saveGState()
    context.translateBy(x: center.x - bounds.midX, y: center.y + bounds.midY)
    context.scaleBy(x: 1, y: -1)
    context.textPosition = .zero
    CTLineDraw(text, context)
    context.restoreGState()
}

render(Banner(name: "Header", width: 3840, height: 1646))
render(Banner(name: "Search Results", width: 3840, height: 2560))
