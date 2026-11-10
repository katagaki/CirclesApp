#!/usr/bin/env swift

// Draws the App Store screenshots: the slides of the Keynote decks in Assets/, rebuilt
// here around fresh captures from Raw/, in English and Japanese.
// Usage: ./compose.swift           (both iPhone and iPad)
//        ./compose.swift iPad
//
// Nothing here opens Keynote. Design/<device>.json describes every slide of a deck: the
// background gradients, the shapes and their colours, the copy with its fonts and
// placement, where each capture and each piece of Artwork/ sits, and Keynote's soft
// effects (clouds, glows and shadows) as outlines with a colour and a blur. The pieces
// of artwork are the image files inside the decks, which are zip archives.
//
// Features newer than the decks get slides drawn here on the opening slide's background,
// with copy of their own, the phone raised so the copy sits centred above it. The slides
// are written to <device>/<language>/.

import AppKit
import CoreText
import ImageIO

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(1)
}

struct Copy {
    let title: String
    let caption: String
}

/// A slide drawn on the opening slide's background, placed after slide `after` of each language.
struct NewSlide {
    let after: Int
    let shot: String
    let copy: [String: Copy]
    /// Drawn as a landscape device under the copy, instead of in the opening slide's phone.
    var isLandscape = false
}

let sharedBuysCopy = [
    "en": Copy(title: "Divide and Conquer", caption: "Share a shopping list and split who buys what"),
    "ja": Copy(title: "友達と共同購入", caption: "リストを共有して、誰が何を買うか分担"),
]
let guideCopy = [
    "en": Copy(title: "Never Get Lost", caption: "Guide walks you to every favorite, booth by booth"),
    "ja": Copy(title: "迷わずサークル巡り", caption: "コミケナビがお気に入りまで道順をご案内"),
]
/// The 8-bit samples of a decoded image, read without any colour conversion.
func samples(of image: CGImage) -> (bytes: [UInt8], perPixel: Int, perRow: Int)? {
    guard image.bitsPerComponent == 8, let data = image.dataProvider?.data as Data? else { return nil }
    return ([UInt8](data), image.bitsPerPixel / 8, image.bytesPerRow)
}

struct Frame {
    let image: CGImage
    let screen: CGRect
    let cornerRadius: CGFloat
    /// How far the capture sits above the middle of the hole, so the status bar lines up
    /// with the Dynamic Island.
    let rise: CGFloat

    /// Frames are drawn at the size of the deck's framed images, with a clear screen.
    init?(width: Int, height: Int) {
        let name = width == 1316 ? "iPhone" : width > height ? "iPad Landscape" : "iPad"
        let url = scriptDir.appendingPathComponent("Frames/\(name).png")
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              image.width == width, image.height == height,
              let (bytes, perPixel, perRow) = samples(of: image) else { return nil }
        self.image = image
        cornerRadius = ["iPhone": 162, "iPad": 40, "iPad Landscape": 42][name]!
        rise = name == "iPhone" ? 3 : 0
        func isClear(_ x: Int, _ y: Int) -> Bool { bytes[y * perRow + x * perPixel + 3] == 0 }
        // Walk out from the middle of the screen to the bezel on each side. Up and down
        // go a third of the way across, clear of the iPhone's Dynamic Island and of the
        // screen's rounded corners.
        let midX = width / 2
        let midY = height / 2
        let column = width / 3
        var left = midX, right = midX, top = midY, bottom = midY
        while left > 0, isClear(left - 1, midY) { left -= 1 }
        while right < width - 1, isClear(right + 1, midY) { right += 1 }
        while top > 0, isClear(column, top - 1) { top -= 1 }
        while bottom < height - 1, isClear(column, bottom + 1) { bottom += 1 }
        // CoreGraphics counts rows from the bottom.
        screen = CGRect(x: left, y: height - bottom - 1, width: right - left + 1, height: bottom - top + 1)
    }
}


func loadRaw(_ shot: String) -> CGImage? {
    let url = scriptDir.appendingPathComponent("Raw/\(shot).png")
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}


func font(_ name: String, japanese: String, size: CGFloat) -> CTFont {
    let descriptor = CTFontDescriptorCreateWithAttributes([
        kCTFontNameAttribute: name,
        kCTFontCascadeListAttribute: [CTFontDescriptorCreateWithNameAndSize(japanese as CFString, size)],
    ] as CFDictionary)
    return CTFontCreateWithFontDescriptor(descriptor, size, nil)
}

/// One centred line, shrunk until it fits `width`, with its baseline at `y`.
func drawLine(_ text: String, font name: String, japanese: String, size: CGFloat, y: CGFloat, width: CGFloat, page: CGRect, in context: CGContext) {
    var size = size
    var line: CTLine
    repeat {
        let attributes = [
            kCTFontAttributeName: font(name, japanese: japanese, size: size),
            kCTForegroundColorAttributeName: CGColor(gray: 1, alpha: 1),
        ] as CFDictionary
        line = CTLineCreateWithAttributedString(CFAttributedStringCreate(nil, text as CFString, attributes)!)
        size -= 2
    } while CTLineGetTypographicBounds(line, nil, nil, nil) > width && size > 10
    let lineWidth = CTLineGetTypographicBounds(line, nil, nil, nil)
    context.textPosition = CGPoint(x: page.midX - lineWidth / 2, y: y)
    CTLineDraw(line, context)
}

func framedImage(_ raw: CGImage, frame: Frame) -> CGImage? {
    let width = frame.image.width
    let height = frame.image.height
    guard let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }
    context.interpolationQuality = .high
    let isTurned = (raw.width > raw.height) != (frame.screen.width > frame.screen.height)
    let size = isTurned ? CGSize(width: raw.height, height: raw.width) : CGSize(width: raw.width, height: raw.height)
    let scale = max(frame.screen.width / size.width, frame.screen.height / size.height)
    context.saveGState()
    context.addPath(CGPath(
        roundedRect: frame.screen, cornerWidth: frame.cornerRadius, cornerHeight: frame.cornerRadius, transform: nil
    ))
    context.clip()
    context.translateBy(x: frame.screen.midX, y: frame.screen.midY + frame.rise)
    if isTurned { context.rotate(by: .pi / 2) }
    let upright = CGSize(width: CGFloat(raw.width) * scale, height: CGFloat(raw.height) * scale)
    context.draw(raw, in: CGRect(x: -upright.width / 2, y: -upright.height / 2, width: upright.width, height: upright.height))
    context.restoreGState()
    context.draw(frame.image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return context.makeImage()
}

/// A landscape device under the copy, with a soft shadow.
func drawLandscapeDevice(_ shot: String, page: CGRect, in context: CGContext) {
    guard let raw = loadRaw(shot), let frame = Frame(width: 2510, height: 1729),
          let image = framedImage(raw, frame: frame) else { fail("cannot frame \(shot)") }
    // Like the decks' own iPads, it is larger than the slide and runs off its right edge,
    // keeping the sidebar whole.
    let width = page.width * 1.3
    let height = width * CGFloat(image.height) / CGFloat(image.width)
    let rect = CGRect(x: page.width * 0.05, y: page.height * 0.79 - height, width: width, height: height)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -page.width * 0.01), blur: page.width * 0.03, color: CGColor(gray: 0, alpha: 0.35))
    context.draw(image, in: rect)
    context.restoreGState()
}


struct Deck {
    let device: String
    let newSlides: [NewSlide]
}

let decks = [
    Deck(device: "iPhone", newSlides: [
        NewSlide(after: 2, shot: "iPhone/12-shared-buys", copy: sharedBuysCopy),
        NewSlide(after: 2, shot: "iPhone/13-guide", copy: guideCopy),
    ]),
    Deck(device: "iPad", newSlides: [
        NewSlide(after: 2, shot: "iPad/12-shared-buys", copy: sharedBuysCopy, isLandscape: true),
        NewSlide(after: 2, shot: "iPad/13-guide", copy: guideCopy, isLandscape: true),
    ]),
]

// MARK: - Design

typealias Element = [String: Any]

func numbers(_ value: Any?) -> [CGFloat] {
    (value as? [Any] ?? []).compactMap { ($0 as? NSNumber).map { CGFloat(truncating: $0) } }
}

func cgColor(_ value: Any?, alpha: CGFloat = 1) -> CGColor {
    let c = numbers(value)
    // A fourth component is the colour's own opacity, as in a fade's gradient stops.
    return CGColor(srgbRed: c.count > 0 ? c[0] : 0, green: c.count > 1 ? c[1] : 0, blue: c.count > 2 ? c[2] : 0,
                   alpha: alpha * (c.count > 3 ? c[3] : 1))
}

func transform(_ value: Any?) -> CGAffineTransform {
    let m = numbers(value)
    guard m.count == 6 else { return .identity }
    return CGAffineTransform(a: m[0], b: m[1], c: m[2], d: m[3], tx: m[4], ty: m[5])
}

/// A path written as segments: ["m", x, y], ["l", x, y], ["c", x1, y1, x2, y2, x, y], ["v", …], ["h"].
func path(_ value: Any?) -> CGPath {
    let path = CGMutablePath()
    for case let segment as [Any] in value as? [Any] ?? [] {
        guard let op = segment.first as? String else { continue }
        let p = numbers(Array(segment.dropFirst()))
        switch op {
        case "m": path.move(to: CGPoint(x: p[0], y: p[1]))
        case "l": path.addLine(to: CGPoint(x: p[0], y: p[1]))
        case "c": path.addCurve(to: CGPoint(x: p[4], y: p[5]), control1: CGPoint(x: p[0], y: p[1]), control2: CGPoint(x: p[2], y: p[3]))
        case "v": path.addCurve(to: CGPoint(x: p[2], y: p[3]), control1: path.currentPoint, control2: CGPoint(x: p[0], y: p[1]))
        case "h": path.closeSubpath()
        default: break
        }
    }
    return path
}

var artworkCache: [String: CGImage] = [:]
func artwork(_ file: String) -> CGImage {
    if let image = artworkCache[file] { return image }
    let url = scriptDir.appendingPathComponent("Artwork/\(file)")
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { fail("missing Artwork/\(file)") }
    artworkCache[file] = image
    return image
}

func textFont(_ name: String, size: CGFloat) -> CTFont {
    if name.hasPrefix("SFPro") {
        return NSFont.systemFont(ofSize: size, weight: name.hasSuffix("Bold") ? .bold : .semibold) as CTFont
    }
    return CTFontCreateWithName(name as CFString, size, nil)
}

func draw(_ element: Element, in context: CGContext) {
    let alpha = CGFloat(truncating: element["alpha"] as? NSNumber ?? 1)
    context.saveGState()
    defer { context.restoreGState() }
    for clip in element["clip"] as? [Any] ?? [] {
        context.addPath(path(clip))
        context.clip()
    }
    switch element["type"] as? String {
    case "fill":
        context.addPath(path(element["path"]))
        context.setFillColor(cgColor(element["color"], alpha: alpha))
        if element["evenOdd"] as? Bool == true { context.fillPath(using: .evenOdd) } else { context.fillPath() }
    case "stroke":
        context.addPath(path(element["path"]))
        context.setStrokeColor(cgColor(element["color"], alpha: alpha))
        context.setLineWidth(CGFloat(truncating: element["width"] as? NSNumber ?? 1))
        context.setLineJoin(.miter)
        context.strokePath()
    case "shading":
        let stops = element["stops"] as? [[Any]] ?? []
        let colors = stops.map { cgColor($0[1], alpha: alpha) } as CFArray
        let locations = stops.map { CGFloat(truncating: $0[0] as? NSNumber ?? 0) }
        guard let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: locations) else { return }
        let c = numbers(element["coords"])
        context.concatenate(transform(element["matrix"]))
        if element["kind"] as? String == "radial", c.count == 6 {
            context.drawRadialGradient(gradient, startCenter: CGPoint(x: c[0], y: c[1]), startRadius: c[2],
                                       endCenter: CGPoint(x: c[3], y: c[4]), endRadius: c[5],
                                       options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        } else if c.count == 4 {
            context.drawLinearGradient(gradient, start: CGPoint(x: c[0], y: c[1]), end: CGPoint(x: c[2], y: c[3]),
                                       options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        }
    case "effect":
        // A soft shape is drawn far off the page and cast back as its shadow, so only the
        // blurred copy lands; its opacity ramp is then laid over it.
        let blur = CGFloat(truncating: element["blur"] as? NSNumber ?? 0)
        let shape = path(element["path"])
        let color = cgColor(element["color"], alpha: alpha)
        let ramp = element["ramp"] as? [String: Any]
        if ramp != nil { context.beginTransparencyLayer(auxiliaryInfo: nil) }
        if blur < 1.5 {
            context.addPath(shape)
            context.setFillColor(color)
            context.fillPath()
        } else {
            let away: CGFloat = 100_000
            context.setShadow(offset: CGSize(width: away, height: 0), blur: blur * 2, color: color)
            var shift = CGAffineTransform(translationX: -away, y: 0)
            if let moved = shape.copy(using: &shift) { context.addPath(moved) }
            context.setFillColor(CGColor(gray: 0, alpha: 1))
            context.fillPath()
            context.setShadow(offset: .zero, blur: 0, color: nil)
        }
        if let ramp {
            let start = numbers(ramp["start"]), end = numbers(ramp["end"]), alphas = numbers(ramp["alphas"])
            let colors = alphas.map { CGColor(gray: 0, alpha: $0) } as CFArray
            let locations = alphas.indices.map { CGFloat($0) / CGFloat(max(alphas.count - 1, 1)) }
            if let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: locations) {
                context.setBlendMode(.destinationIn)
                context.drawLinearGradient(gradient, start: CGPoint(x: start[0], y: start[1]), end: CGPoint(x: end[0], y: end[1]),
                                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            }
            context.endTransparencyLayer()
        }
    case "artwork":
        context.concatenate(transform(element["matrix"]))
        context.setAlpha(alpha)
        context.interpolationQuality = .high
        context.draw(artwork(element["file"] as? String ?? ""), in: CGRect(x: 0, y: 0, width: 1, height: 1))
    case "capture":
        let size = numbers(element["size"])
        guard let raw = loadRaw(element["shot"] as? String ?? ""),
              let frame = Frame(width: Int(size[0]), height: Int(size[1])),
              let image = framedImage(raw, frame: frame) else { fail("cannot frame \(element["shot"] ?? "")") }
        context.concatenate(transform(element["matrix"]))
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
    case "text":
        let m = numbers(element["matrix"])
        let size = hypot(m[0], m[1])
        guard size > 0, let text = element["text"] as? String, !text.isEmpty else { return }
        context.concatenate(CGAffineTransform(a: m[0] / size, b: m[1] / size, c: m[2] / size, d: m[3] / size, tx: m[4], ty: m[5]))
        let attributes = [
            kCTFontAttributeName: textFont(element["font"] as? String ?? "HelveticaNeue", size: size),
            kCTForegroundColorAttributeName: cgColor(element["color"], alpha: alpha),
        ] as CFDictionary
        let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(nil, text as CFString, attributes)!)
        context.textMatrix = .identity
        context.textPosition = .zero
        if let glow = element["glow"] as? [String: Any] {
            // Only the blurred copy lands: the text itself is drawn far off the page.
            let away: CGFloat = 100_000
            let blur = CGFloat(truncating: glow["blur"] as? NSNumber ?? 0)
            context.setShadow(offset: CGSize(width: away, height: 0), blur: blur * 2,
                              color: cgColor(glow["color"], alpha: CGFloat(truncating: glow["alpha"] as? NSNumber ?? 1)))
            context.textPosition = CGPoint(x: -away, y: 0)
        }
        CTLineDraw(line, context)
    default:
        break
    }
}

// MARK: - New slides

/// The baselines and sizes of a slide's title and first caption line.
func copyMetrics(_ elements: [Element]) -> (title: (y: CGFloat, size: CGFloat), caption: (y: CGFloat, size: CGFloat))? {
    let lines = elements.filter { $0["type"] as? String == "text" }.map { numbers($0["matrix"]) }.map { (y: $0[5], size: hypot($0[0], $0[1])) }
    guard let largest = lines.map(\.size).max(), let title = lines.first(where: { $0.size == largest }),
          let caption = lines.first(where: { $0.size < largest && $0.y < title.y }) else { return nil }
    return (title, caption)
}

/// The opening slide's background and clouds, then its phone with its glow when `shot` is given.
func newSlideBase(_ opening: [Element], shot: String?) -> (background: [Element], device: [Element]) {
    var base: [Element] = []
    var device: [Element] = []
    var cloud = false
    for (index, element) in opening.enumerated() {
        switch element["type"] as? String {
        case "shading" where base.isEmpty: base.append(element)
        case "effect" where !cloud: base.append(element); cloud = true
        case "capture":
            guard let shot else { continue }
            // The phone's glow sits just before it, behind the logo drawn in between.
            if let glow = opening[..<index].last(where: { $0["type"] as? String == "effect" }) { device.append(glow) }
            var phone = element
            phone["shot"] = shot
            // Its clip held it below the opening slide's copy; the phone moves, so it goes.
            phone["clip"] = nil
            device.append(phone)
        default: break
        }
    }
    return (base, device)
}

/// How far to raise the phone so the copy sits centred between the top of the slide and
/// the top of the phone.
func centringRise(_ device: [Element], metrics: (title: (y: CGFloat, size: CGFloat), caption: (y: CGFloat, size: CGFloat)), height: CGFloat) -> CGFloat {
    guard let phone = device.last(where: { $0["type"] as? String == "capture" }) else { return 0 }
    let m = numbers(phone["matrix"])
    let top = m[5] + m[3]
    let copyTop = metrics.title.y + metrics.title.size * 0.72
    let copyBottom = metrics.caption.y - metrics.caption.size * 0.22
    return (copyTop + copyBottom) - height - top
}

// MARK: - Composition

func render(size: CGSize, to url: URL, _ draw: (CGContext, CGRect) -> Void) {
    guard let context = CGContext(
        data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { fail("no context for \(url.lastPathComponent)") }
    context.setFillColor(.white)
    context.fill(CGRect(origin: .zero, size: size))
    draw(context, CGRect(origin: .zero, size: size))
    guard let image = context.makeImage(),
          let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)
    else { fail("could not write \(url.lastPathComponent)") }
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
    print("wrote \(url.path.replacingOccurrences(of: scriptDir.path + "/", with: ""))")
}

func compose(_ deck: Deck) {
    let url = scriptDir.appendingPathComponent("Design/\(deck.device).json")
    guard let data = try? Data(contentsOf: url),
          let design = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let slides = design["slides"] as? [[String: Any]] else { fail("cannot read Design/\(deck.device).json") }
    let size = CGSize(width: CGFloat(truncating: design["width"] as? NSNumber ?? 0), height: CGFloat(truncating: design["height"] as? NSNumber ?? 0))
    for language in ["en", "ja"] {
        let directory = scriptDir.appendingPathComponent("\(deck.device)/\(language)")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let pages = slides.filter { $0["language"] as? String == language }.map { $0["elements"] as? [Element] ?? [] }
        guard let opening = pages.first else { continue }
        var number = 0
        func next() -> URL {
            number += 1
            return directory.appendingPathComponent(String(format: "%02d.png", number))
        }
        for (position, elements) in pages.enumerated() {
            render(size: size, to: next()) { context, _ in
                for element in elements { draw(element, in: context) }
            }
            for slide in deck.newSlides where slide.after == position + 1 {
                guard let copy = slide.copy[language], let metrics = copyMetrics(opening) else { fail("cannot read the opening slide's copy") }
                render(size: size, to: next()) { context, bounds in
                    let base = newSlideBase(opening, shot: slide.isLandscape ? nil : slide.shot)
                    for element in base.background { draw(element, in: context) }
                    context.saveGState()
                    context.translateBy(x: 0, y: centringRise(base.device, metrics: metrics, height: bounds.height))
                    for element in base.device { draw(element, in: context) }
                    context.restoreGState()
                    if slide.isLandscape { drawLandscapeDevice(slide.shot, page: bounds, in: context) }
                    let width = bounds.width * 0.9
                    drawLine(copy.title, font: "HelveticaNeue-CondensedBlack", japanese: "HiraginoSans-W8",
                             size: metrics.title.size, y: metrics.title.y, width: width, page: bounds, in: context)
                    drawLine(copy.caption, font: "HelveticaNeue-Bold", japanese: "HiraginoSans-W6",
                             size: metrics.caption.size, y: metrics.caption.y, width: width, page: bounds, in: context)
                }
            }
        }
    }
}

let arguments = Array(CommandLine.arguments.dropFirst())
for deck in decks where arguments.isEmpty || arguments.contains(deck.device) {
    compose(deck)
}
