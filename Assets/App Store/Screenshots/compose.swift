#!/usr/bin/env swift

// Lays the raw captures into the App Store designs and writes the screenshots.
// Usage: ./compose.swift                              (both iPhone and iPad)
//        ./compose.swift iPad
//        ./compose.swift template iPhone <exported.pdf>
//
// The design lives in the Keynote decks in Assets/. Templates/ holds each deck as a PDF,
// every slide with its own artwork, but with each screenshot swapped for a flat
// placeholder colour. Composing fills those placeholders with fresh captures from Raw/ in
// a device frame from Frames/, and renders the pages: no Keynote is needed.
//
// When a deck changes, export it from Keynote (File > Export To > PDF) and rebuild its
// template with the `template` command. That finds the screenshots by matching them to
// the image files inside the deck, drops the clocks laid over them, and shrinks photos.
//
// Features newer than the decks get slides drawn here: the opening slide's background, a
// phone, the copy, and stickers of their own. The slides before the deck's blank slide
// are English and the ones after it are Japanese.

import AppKit
import CoreText
import ImageIO

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let assetsDir = scriptDir.deletingLastPathComponent().deletingLastPathComponent()

struct Deck {
    let device: String
    let keynote: String
    /// The deck's image files, by name without the suffix Keynote adds, and the capture
    /// that replaces each, as `<device>/<shot>`. The order sets the placeholder colours.
    let shots: [(image: String, shot: String)]
    let newSlides: [NewSlide]

    var template: URL { scriptDir.appendingPathComponent("Templates/\(device).pdf") }
}

struct Copy {
    let title: String
    let caption: String
}

struct Sticker {
    let symbol: String
    let color: NSColor
    /// Centre, as a fraction of the slide, from the top-left.
    let x: CGFloat
    let y: CGFloat
    let angle: CGFloat
}

/// A slide drawn on the opening slide's background, placed after slide `after` of each language.
struct NewSlide {
    let after: Int
    let shot: String
    let copy: [String: Copy]
    let stickers: [Sticker]
    /// Drawn as a landscape device under the copy, instead of in the opening slide's phone.
    var isLandscape = false
}

func color(_ hex: UInt32) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255, alpha: 1
    )
}

let sharedBuysCopy = [
    "en": Copy(title: "Divide and Conquer", caption: "Share a shopping list and split who buys what"),
    "ja": Copy(title: "友達と共同購入", caption: "リストを共有して、誰が何を買うか分担"),
]
let sharedBuysStickers = [
    Sticker(symbol: "person.2.fill", color: color(0x7B4BD6), x: 0.09, y: 0.68, angle: 12),
    Sticker(symbol: "qrcode", color: color(0x1C1C1E), x: 0.91, y: 0.49, angle: -10),
    Sticker(symbol: "yensign", color: color(0x2EA666), x: 0.12, y: 0.86, angle: -8),
]
let guideCopy = [
    "en": Copy(title: "Never Get Lost", caption: "Navi walks you to every favorite, booth by booth"),
    "ja": Copy(title: "迷わずサークル巡り", caption: "コミケナビがお気に入りまで道順をご案内"),
]
let guideStickers = [
    Sticker(symbol: "figure.walk", color: color(0x34C759), x: 0.09, y: 0.58, angle: -11),
    Sticker(symbol: "arrow.turn.up.right", color: color(0x3478F6), x: 0.91, y: 0.50, angle: 10),
    Sticker(symbol: "flag.checkered", color: color(0xFF3B30), x: 0.90, y: 0.84, angle: 7),
]

let iPadSharedBuysStickers = [
    Sticker(symbol: "person.2.fill", color: color(0x7B4BD6), x: 0.08, y: 0.24, angle: 12),
    Sticker(symbol: "qrcode", color: color(0x1C1C1E), x: 0.88, y: 0.86, angle: -10),
    Sticker(symbol: "yensign", color: color(0x2EA666), x: 0.10, y: 0.84, angle: -8),
]
let iPadGuideStickers = [
    Sticker(symbol: "figure.walk", color: color(0x34C759), x: 0.09, y: 0.84, angle: -11),
    Sticker(symbol: "arrow.turn.up.right", color: color(0x3478F6), x: 0.90, y: 0.24, angle: 10),
    Sticker(symbol: "flag.checkered", color: color(0xFF3B30), x: 0.86, y: 0.86, angle: 7),
]

let decks = [
    Deck(device: "iPhone", keynote: "App Store 26+ (6.5inch iPhone).key", shots: [
        ("CiRCLES 26+ 1", "iPhone/01-map"),
        ("CiRCLES 26+ 2", "iPhone/02-grid"),
        ("CiRCLES 26+ 3", "iPhone/03-list"),
        ("CiRCLES 26+ 4", "iPhone/04-detail"),
        ("CiRCLES 26+ 5", "iPhone/05-translate"),
        ("CiRCLES 26+ 6", "iPhone/06-links"),
        ("CiRCLES 26+ 7", "iPhone/07-context-menu"),
        ("CiRCLES 26+ 8", "iPhone/08-favorite"),
        ("CiRCLES 26+ 9", "iPhone/09-my"),
        ("CiRCLES 26+ 10", "iPhone/10-more"),
        ("CiRCLES 26+ 12", "iPhone/11-visits"),
    ], newSlides: [
        NewSlide(after: 2, shot: "iPhone/12-shared-buys", copy: sharedBuysCopy, stickers: sharedBuysStickers),
        NewSlide(after: 2, shot: "iPhone/13-guide", copy: guideCopy, stickers: guideStickers),
    ]),
    Deck(device: "iPad", keynote: "App Store 26+ (12.9inch iPad Pro).key", shots: [
        ("CiRCLES iPad 26+ 01", "iPad/01-map"),
        ("CiRCLES iPad 26+ 02", "iPad/02-list"),
        ("CiRCLES iPad 26+ 03", "iPad/03-grid"),
        ("CiRCLES iPad 26+ 04", "iPad/04-detail"),
        ("CiRCLES 26+ 5", "iPhone/05-translate"),
        ("CiRCLES iPad 26+ 06", "iPad/06-links"),
        ("CiRCLES iPad 26+ 07", "iPad/07-context-menu"),
        ("CiRCLES iPad 26+ 08", "iPad/08-favorite"),
        ("CiRCLES iPad 26+ 09", "iPad/11-visits"),
        ("CiRCLES iPad 26+ 10a", "iPad/09-my"),
        ("CiRCLES iPad 26+ 11", "iPad/10-more"),
    ], newSlides: [
        NewSlide(after: 2, shot: "iPad/12-shared-buys", copy: sharedBuysCopy, stickers: iPadSharedBuysStickers, isLandscape: true),
        NewSlide(after: 2, shot: "iPad/13-guide", copy: guideCopy, stickers: iPadGuideStickers, isLandscape: true),
    ]),
]

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(1)
}

/// The placeholder colour for a deck's `index`th screenshot.
func placeholderColor(_ index: Int) -> (UInt8, UInt8, UInt8) {
    (UInt8(8 + index * 20), 250, 6)
}

// MARK: - PDF

/// A PDF 1.3 file as Keynote writes it: a classic cross-reference table, no object streams.
struct PDF {
    var objects: [Int: Data] = [:]
    var trailer = ""

    init(_ data: Data) {
        let bytes = [UInt8](data)
        let tail = String(decoding: bytes.suffix(1024), as: UTF8.self)
        guard let start = tail.components(separatedBy: "startxref").last?
            .split(whereSeparator: \.isWhitespace).first.flatMap({ Int($0) }) else { fail("no startxref") }
        let table = String(decoding: bytes[start...], as: UTF8.self)
        let lines = table.components(separatedBy: .newlines)
        var offsets: [(Int, Int)] = []
        var index = 1
        var number = 0
        while index < lines.count, !lines[index].hasPrefix("trailer") {
            let fields = lines[index].split(separator: " ")
            if fields.count == 2, let first = Int(fields[0]) {
                number = first
            } else if fields.count == 3, fields[2] == "n", let offset = Int(fields[0]) {
                offsets.append((number, offset))
                number += 1
            } else if fields.count == 3 {
                number += 1
            }
            index += 1
        }
        trailer = table.components(separatedBy: "trailer").last?
            .components(separatedBy: "startxref").first ?? ""
        let sorted = offsets.sorted { $0.1 < $1.1 }
        for (position, (number, offset)) in sorted.enumerated() {
            let end = position + 1 < sorted.count ? sorted[position + 1].1 : start
            objects[number] = data.subdata(in: offset..<end)
        }
    }

    /// The object's dictionary, up to its stream.
    func header(_ number: Int) -> String {
        guard let object = objects[number] else { return "" }
        let end = object.range(of: Data("stream".utf8))?.lowerBound ?? object.endIndex
        return String(decoding: object[object.startIndex..<end], as: UTF8.self)
    }

    func stream(_ number: Int) -> Data? {
        guard let object = objects[number],
              let open = object.range(of: Data("stream".utf8)),
              let length = integer("Length", in: header(number)) else { return nil }
        var start = open.upperBound
        if object[start] == 0x0D { start += 1 }
        if object[start] == 0x0A { start += 1 }
        return object.subdata(in: start..<(start + length))
    }

    func integer(_ key: String, in dictionary: String) -> Int? {
        guard let range = dictionary.range(of: "/\(key)\\s+(\\d+)(?!\\s+\\d+\\s+R)", options: .regularExpression) else {
            return nil
        }
        return Int(dictionary[range].split(whereSeparator: \.isWhitespace)[1])
    }

    /// Replaces a stream's contents. `filter` names how `contents` is encoded, and
    /// `entries` replaces dictionary values such as an image's size.
    mutating func replaceStream(_ number: Int, with contents: Data, filter: String? = nil, entries: [String: String] = [:]) {
        let dictionary = header(number)
        guard let open = dictionary.range(of: "<<"), let close = dictionary.range(of: ">>", options: .backwards) else {
            return
        }
        var body = String(dictionary[open.upperBound..<close.lowerBound])
        body = body.replacingOccurrences(of: #"/Length\s+\d+"#, with: "/Length \(contents.count)", options: .regularExpression)
        body = body.replacingOccurrences(of: #"/Filter\s*/\w+"#, with: "", options: .regularExpression)
        body = body.replacingOccurrences(of: #"/DecodeParms\s*<<[^>]*>>"#, with: "", options: .regularExpression)
        for (key, value) in entries {
            body = body.replacingOccurrences(of: "/\(key)\\s+\\d+", with: "/\(key) \(value)", options: .regularExpression)
        }
        if let filter { body += " /Filter /\(filter)" }
        var object = Data("\(number) 0 obj\n<<\(body)>>\nstream\n".utf8)
        object.append(contents)
        object.append(Data("\nendstream\nendobj\n".utf8))
        objects[number] = object
    }

    /// The object numbers of the pages, in order.
    var pages: [Int] {
        guard let root = integer("Root", in: trailer.replacingOccurrences(of: " 0 R", with: "")),
              let tree = integer("Pages", in: header(root).replacingOccurrences(of: " 0 R", with: "")) else { return [] }
        func walk(_ number: Int) -> [Int] {
            let dictionary = header(number)
            guard dictionary.range(of: #"/Type\s*/Pages"#, options: .regularExpression) != nil,
                  let kids = dictionary.range(of: #"/Kids\s*\[[^\]]*\]"#, options: .regularExpression) else { return [number] }
            return dictionary[kids].matches(of: #/(\d+) 0 R/#).flatMap { walk(Int($0.1)!) }
        }
        return walk(tree)
    }

    func reference(_ key: String, in number: Int) -> Int? {
        guard let range = header(number).range(of: "/\(key)\\s+\\d+\\s+0\\s+R", options: .regularExpression) else { return nil }
        return Int(header(number)[range].split(whereSeparator: \.isWhitespace)[1])
    }

    /// A page's content stream, decoded.
    func contents(ofPage page: Int) -> (number: Int, data: Data)? {
        guard let number = reference("Contents", in: page), let stream = stream(number), let data = inflate(stream) else { return nil }
        return (number, data)
    }

    /// The image objects a page names in its resources, by name.
    func images(ofPage page: Int) -> [String: Int] {
        var resources = header(page)
        if let number = reference("Resources", in: page) { resources = header(number) }
        guard let range = resources.range(of: #"/XObject\s*<<[^>]*>>"#, options: .regularExpression) else { return [:] }
        var names: [String: Int] = [:]
        for match in resources[range].matches(of: #/\/(\w+)\s+(\d+) 0 R/#) { names[String(match.1)] = Int(match.2) }
        return names
    }

    var data: Data {
        var out = Data("%PDF-1.3\n".utf8)
        let count = (objects.keys.max() ?? 0) + 1
        var offsets = [Int](repeating: 0, count: count)
        for number in objects.keys.sorted() {
            offsets[number] = out.count
            out.append(objects[number]!)
        }
        let start = out.count
        var table = "xref\n0 \(count)\n0000000000 65535 f \n"
        for number in 1..<count {
            table += objects[number] == nil
                ? "0000000000 65535 f \n"
                : String(format: "%010d 00000 n \n", offsets[number])
        }
        let entries = trailer.replacingOccurrences(of: #"/Size\s+\d+"#, with: "/Size \(count)", options: .regularExpression)
        table += "trailer\n\(entries.trimmingCharacters(in: .whitespacesAndNewlines))\nstartxref\n\(start)\n%%EOF\n"
        out.append(Data(table.utf8))
        return out
    }
}

/// zlib's framing around a raw deflate stream, which is what `NSData` inflates.
func inflate(_ data: Data) -> Data? {
    guard data.count > 6 else { return nil }
    return try? (data.subdata(in: 2..<(data.count - 4)) as NSData).decompressed(using: .zlib) as Data
}

/// Widens the patch the decks lay over the nickname on the account screen.
///
/// The patch is a rectangle in the app's grouped background colour with a made-up
/// nickname set on it, sized for an older capture's name. It is the only rectangle in
/// that colour drawn just before a text, once the clocks are gone, and is widened in place.
func wideningNamePatch(in contents: Data) -> Data? {
    guard let text = String(data: contents, encoding: .isoLatin1),
          let marker = try? NSRegularExpression(pattern: #"/P\s*<<\s*/MCID\s+\d+\s*>>\s*BDC"#) else { return nil }
    let starts = marker.matches(in: text, range: NSRange(text.startIndex..., in: text)).map(\.range.location)
    guard !starts.isEmpty else { return nil }
    let source = text as NSString
    var blocks = [source.substring(to: starts[0])]
    for (index, start) in starts.enumerated() {
        let end = index + 1 < starts.count ? starts[index + 1] : source.length
        blocks.append(source.substring(with: NSRange(location: start, length: end - start)))
    }
    var changed = false
    for index in blocks.indices.dropFirst(2) where blocks[index].contains(try! Regex(#"\sTf\s"#)) {
        let patch = blocks[index - 1]
        guard patch.contains(try! Regex(#"0\.94\d*\s+0\.94\d*\s+0\.96\d*\s+sc"#)) else { continue }
        guard let rectangle = patch.ranges(of: #/([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s+re\s+f/#).last,
              let match = patch[rectangle].firstMatch(of: #/([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s+re\s+f/#),
              let x = Double(match.1), let y = Double(match.2), let width = Double(match.3), let height = Double(match.4)
        else { continue }
        let wider = width * 1.75
        let replacement = String(format: "%.4f %.4f %.4f %.4f re f", x - (wider - width) / 2, y, wider, height)
        blocks[index - 1] = patch.replacingCharacters(in: rectangle, with: replacement)
        changed = true
    }
    return changed ? blocks.joined().data(using: .isoLatin1) : nil
}

/// A zlib stream, as `/FlateDecode` expects: deflate with its header and checksum.
func deflate(_ data: Data) -> Data {
    guard let body = try? (data as NSData).compressed(using: .zlib) as Data else { fail("could not compress") }
    var a: UInt32 = 1
    var b: UInt32 = 0
    for byte in data {
        a = (a + UInt32(byte)) % 65521
        b = (b + a) % 65521
    }
    var out = Data([0x78, 0x9C])
    out.append(body)
    out.append(contentsOf: [UInt8(b >> 8), UInt8(b & 0xFF), UInt8(a >> 8), UInt8(a & 0xFF)])
    return out
}

/// Blanks the clocks laid over the phones in the decks, and the patches behind them. They
/// hid the times in older captures, which now all read 9:41.
///
/// Each Keynote item is its own marked-content block. A clock is a text box, drawn in
/// Keynote's `/Tc` fonts, whose text starts with a time; its patch is the plain filled
/// rectangle just before it. Only their marks are dropped, so the graphics state stays
/// balanced.
func removingClocks(from contents: Data) -> Data? {
    guard let text = String(data: contents, encoding: .isoLatin1) else { return nil }
    guard let marker = try? NSRegularExpression(pattern: #"/P\s*<<\s*/MCID\s+\d+\s*>>\s*BDC"#) else { return nil }
    let starts = marker.matches(in: text, range: NSRange(text.startIndex..., in: text)).map(\.range.location)
    guard !starts.isEmpty else { return nil }
    let source = text as NSString
    var blocks = [source.substring(to: starts[0])]
    for (index, start) in starts.enumerated() {
        let end = index + 1 < starts.count ? starts[index + 1] : source.length
        blocks.append(source.substring(with: NSRange(location: start, length: end - start)))
    }
    let shown = #"\(((?:[^)\\]|\\.)*)\)\s*Tj"#
    let anyShown = #"(\((?:[^)\\]|\\.)*\)|<[0-9A-Fa-f\s]*>)\s*Tj|\[[^\]]*\]\s*TJ"#
    func shownText(_ block: String) -> String {
        guard let pattern = try? NSRegularExpression(pattern: shown) else { return "" }
        let range = NSRange(block.startIndex..., in: block)
        return pattern.matches(in: block, range: range)
            .map { (block as NSString).substring(with: $0.range(at: 1)) }.joined()
    }
    var changed = false
    for index in blocks.indices where blocks[index].contains("/Tc") {
        guard shownText(blocks[index]).range(of: #"^\s*\d{1,2}[!:]?\d{2}"#, options: .regularExpression) != nil
        else { continue }
        blocks[index] = blocks[index].replacingOccurrences(of: anyShown, with: "() Tj", options: .regularExpression)
        let patch = index > 1 ? blocks[index - 1] : ""
        let fill = #"(?<=\s)(f\*?|F)(?=\s)"#
        if patch.range(of: fill, options: .regularExpression) != nil, !patch.contains("Tj"), !patch.contains(" Do") {
            blocks[index - 1] = patch.replacingOccurrences(of: fill, with: "n", options: .regularExpression)
        }
        changed = true
    }
    return changed ? blocks.joined().data(using: .isoLatin1) : nil
}

/// The 8-bit RGB samples of a decoded image, read without any colour conversion.
func samples(of image: CGImage) -> (bytes: [UInt8], perPixel: Int, perRow: Int)? {
    guard image.bitsPerComponent == 8, let data = image.dataProvider?.data as Data? else { return nil }
    return ([UInt8](data), image.bitsPerPixel / 8, image.bytesPerRow)
}

/// How far a PDF image's samples are from the deck image's, on a grid of pixels. Older
/// captures of one screen can be close, so the nearest is the one placed.
func difference(_ pdfSamples: Data, _ image: CGImage) -> Int? {
    guard let (bytes, perPixel, perRow) = samples(of: image) else { return nil }
    let width = image.width
    let height = image.height
    guard pdfSamples.count == width * height * 3 else { return nil }
    let pdfBytes = [UInt8](pdfSamples)
    var difference = 0
    for y in stride(from: height / 24, to: height, by: height / 24) {
        for x in stride(from: width / 24, to: width, by: width / 24) {
            for channel in 0..<3 {
                difference += abs(Int(pdfBytes[(y * width + x) * 3 + channel]) - Int(bytes[y * perRow + x * perPixel + channel]))
            }
        }
    }
    return difference
}

// MARK: - Device frames

struct Frame {
    let image: CGImage
    let screen: CGRect

    /// Frames are drawn at the size of the deck's framed images, with a clear screen.
    init?(width: Int, height: Int) {
        let name = width == 1316 ? "iPhone" : width > height ? "iPad Landscape" : "iPad"
        let url = scriptDir.appendingPathComponent("Frames/\(name).png")
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              image.width == width, image.height == height,
              let (bytes, perPixel, perRow) = samples(of: image) else { return nil }
        self.image = image
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

/// A capture in its device frame, as 8-bit RGB samples in the deck image's colour space.
func framedSamples(raw: CGImage, frame: Frame, like original: CGImage) -> Data? {
    let width = frame.image.width
    let height = frame.image.height
    let space = original.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
    guard let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
        space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { return nil }
    context.interpolationQuality = .high
    // XCUITest saves landscape captures upright to the device, so they are turned a
    // quarter anticlockwise to fit a landscape frame.
    let isTurned = (raw.width > raw.height) != (frame.screen.width > frame.screen.height)
    let rawSize = isTurned
        ? CGSize(width: raw.height, height: raw.width) : CGSize(width: raw.width, height: raw.height)
    let scale = max(frame.screen.width / rawSize.width, frame.screen.height / rawSize.height)
    let drawSize = CGSize(width: rawSize.width * scale, height: rawSize.height * scale)
    context.saveGState()
    context.translateBy(x: frame.screen.midX, y: frame.screen.midY)
    if isTurned { context.rotate(by: .pi / 2) }
    let upright = isTurned ? CGSize(width: drawSize.height, height: drawSize.width) : drawSize
    context.draw(raw, in: CGRect(
        x: -upright.width / 2, y: -upright.height / 2, width: upright.width, height: upright.height
    ))
    context.restoreGState()
    context.draw(frame.image, in: CGRect(x: 0, y: 0, width: width, height: height))
    guard let pixels = context.data else { return nil }
    let rgba = pixels.bindMemory(to: UInt8.self, capacity: width * height * 4)
    var rgb = Data(count: width * height * 3)
    rgb.withUnsafeMutableBytes { buffer in
        let out = buffer.bindMemory(to: UInt8.self)
        for pixel in 0..<(width * height) {
            out[pixel * 3] = rgba[pixel * 4]
            out[pixel * 3 + 1] = rgba[pixel * 4 + 1]
            out[pixel * 3 + 2] = rgba[pixel * 4 + 2]
        }
    }
    return rgb
}

func loadRaw(_ shot: String) -> CGImage? {
    let url = scriptDir.appendingPathComponent("Raw/\(shot).png")
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

/// Whether a PDF image is a placeholder, judged by its screen colour at a few points.
func isPlaceholder(_ samples: Data, width: Int, height: Int, color: (UInt8, UInt8, UInt8)) -> Bool {
    guard samples.count == width * height * 3 else { return false }
    let points = [(width / 2, height / 2), (width / 3, height / 3), (2 * width / 3, 2 * height / 3)]
    return points.allSatisfy { x, y in
        let offset = (y * width + x) * 3
        return abs(Int(samples[offset]) - Int(color.0)) < 12
            && abs(Int(samples[offset + 1]) - Int(color.1)) < 12
            && abs(Int(samples[offset + 2]) - Int(color.2)) < 12
    }
}

// MARK: - Templates

/// The deck's own image files, keyed by name, with Keynote's `-1234` suffix removed. A
/// `.key` is a zip archive, so they are read without Keynote.
func deckImages(_ deck: Deck) -> [String: CGImage] {
    let work = FileManager.default.temporaryDirectory.appendingPathComponent("circles-deck-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: work) }
    let unzip = Process()
    unzip.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
    unzip.arguments = ["-x", "-k", assetsDir.appendingPathComponent(deck.keynote).path, work.path]
    do { try unzip.run() } catch { fail("could not open \(deck.keynote)") }
    unzip.waitUntilExit()
    let data = work.appendingPathComponent("Data")
    let names = Set(deck.shots.map(\.image))
    var images: [String: CGImage] = [:]
    for file in (try? FileManager.default.contentsOfDirectory(atPath: data.path)) ?? [] where !file.contains("-small-") {
        let name = file.replacingOccurrences(of: #"-\d+\.png$"#, with: "", options: .regularExpression)
        guard names.contains(name),
              let bytes = try? Data(contentsOf: data.appendingPathComponent(file)),
              let source = CGImageSourceCreateWithData(bytes as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { continue }
        images[name] = image
    }
    return images
}

/// An image object's size and decoded samples, when it is one this script can read.
func imageSamples(_ pdf: PDF, _ number: Int) -> (width: Int, height: Int, samples: Data)? {
    let header = pdf.header(number)
    guard header.range(of: #"/Subtype\s*/Image"#, options: .regularExpression) != nil,
          header.contains("FlateDecode"),
          let width = pdf.integer("Width", in: header), let height = pdf.integer("Height", in: header),
          let stream = pdf.stream(number), let samples = inflate(stream),
          samples.count == width * height * 3 else { return nil }
    return (width, height, samples)
}

/// A photo re-encoded as a JPEG no larger than `limit` on its long side.
func jpeg(_ samples: Data, width: Int, height: Int, limit: Int) -> (data: Data, width: Int, height: Int)? {
    guard let provider = CGDataProvider(data: samples as CFData),
          let image = CGImage(
            width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 24, bytesPerRow: width * 3,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGBitmapInfo(rawValue: 0),
            provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent
          ) else { return nil }
    let scale = min(1, CGFloat(limit) / CGFloat(max(width, height)))
    let size = (width: Int(CGFloat(width) * scale), height: Int(CGFloat(height) * scale))
    guard let context = CGContext(
        data: nil, width: size.width, height: size.height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { return nil }
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    let data = NSMutableData()
    guard let scaled = context.makeImage(),
          let destination = CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil) else { return nil }
    CGImageDestinationAddImage(destination, scaled, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { return nil }
    return (data as Data, size.width, size.height)
}

func buildTemplate(_ deck: Deck, from exported: URL) {
    guard let data = try? Data(contentsOf: exported) else { fail("cannot read \(exported.path)") }
    var pdf = PDF(data)
    let images = deckImages(deck)
    var found: Set<String> = []
    for number in pdf.objects.keys.sorted() {
        guard let (width, height, samples) = imageSamples(pdf, number) else { continue }
        let match = images
            .filter { $0.value.width == width && $0.value.height == height }
            .compactMap { image in difference(samples, image.value).map { (image.key, $0) } }
            .filter { $0.1 < 400 }.min { $0.1 < $1.1 }?.0
        if let match, let index = deck.shots.firstIndex(where: { $0.image == match }) {
            let color = placeholderColor(index)
            var flat = Data(count: width * height * 3)
            flat.withUnsafeMutableBytes { buffer in
                for pixel in 0..<(width * height) {
                    buffer[pixel * 3] = color.0
                    buffer[pixel * 3 + 1] = color.1
                    buffer[pixel * 3 + 2] = color.2
                }
            }
            pdf.replaceStream(number, with: deflate(flat), filter: "FlateDecode")
            found.insert(match)
        } else if width * height > 4_000_000, !pdf.header(number).contains("/SMask"),
                  let photo = jpeg(samples, width: width, height: height, limit: 2400) {
            pdf.replaceStream(number, with: photo.data, filter: "DCTDecode",
                              entries: ["Width": "\(photo.width)", "Height": "\(photo.height)"])
        }
    }
    for page in pdf.pages {
        guard let (number, contents) = pdf.contents(ofPage: page) else { continue }
        let cleaned = removingClocks(from: contents) ?? contents
        let widened = wideningNamePatch(in: cleaned) ?? cleaned
        guard widened != contents else { continue }
        pdf.replaceStream(number, with: deflate(widened), filter: "FlateDecode")
    }
    let unused = Set(deck.shots.map(\.image)).subtracting(found)
    if !unused.isEmpty { fail("not found in the export: \(unused.sorted().joined(separator: ", "))") }
    try? FileManager.default.createDirectory(at: deck.template.deletingLastPathComponent(), withIntermediateDirectories: true)
    do { try pdf.data.write(to: deck.template) } catch { fail("could not write \(deck.template.path)") }
    print("wrote Templates/\(deck.device).pdf")
}

// MARK: - New slides

/// The opening slide with only its background and phone: its text and logo are dropped,
/// and the phone shows `capture` instead.
///
/// Every Keynote item is a marked-content block that closes the previous item's state and
/// opens its own, so whole blocks can be dropped without unbalancing the page.
func newSlideBase(_ pdf: PDF, page: Int, capture: Data?) -> PDF? {
    var copy = pdf
    guard let (contentsNumber, contents) = pdf.contents(ofPage: page),
          let text = String(data: contents, encoding: .isoLatin1),
          let marker = try? NSRegularExpression(pattern: #"/P\s*<<\s*/MCID\s+\d+\s*>>\s*BDC"#) else { return nil }
    let starts = marker.matches(in: text, range: NSRange(text.startIndex..., in: text)).map(\.range.location)
    let source = text as NSString
    var kept = source.substring(to: starts.first ?? source.length)
    for (index, start) in starts.enumerated() {
        let end = index + 1 < starts.count ? starts[index + 1] : source.length
        let block = source.substring(with: NSRange(location: start, length: end - start))
        // Without a capture only the first image, the cloud, is kept.
        if block.contains(" Do"), capture != nil || !kept.contains(" Do") { kept += block }
    }
    guard let capture else {
        copy.replaceStream(contentsNumber, with: Data(kept.utf8))
        return copy
    }
    // The phone is the image the size of a device frame; it gets a new object of its own.
    let names = pdf.images(ofPage: page)
    guard let (name, number) = names.first(where: { _, number in
              pdf.integer("Width", in: pdf.header(number)).map { [1316, 1728].contains($0) } ?? false
          }) else { return nil }
    let phone = (pdf.objects.keys.max() ?? 0) + 1
    var object = pdf.objects[number]!
    if let label = object.range(of: Data("\(number) 0 obj".utf8)) {
        object.replaceSubrange(label, with: Data("\(phone) 0 obj".utf8))
    }
    copy.objects[phone] = object
    copy.replaceStream(phone, with: capture)
    kept = kept.replacingOccurrences(of: "/\(name) Do", with: "/NewPhone Do")
    copy.replaceStream(contentsNumber, with: Data(kept.utf8))
    let resources = pdf.reference("Resources", in: page) ?? page
    if let object = copy.objects[resources], let dictionary = String(data: object, encoding: .isoLatin1),
       let range = dictionary.range(of: #"/XObject\s*<<"#, options: .regularExpression) {
        let updated = dictionary.replacingCharacters(in: range, with: "/XObject << /NewPhone \(phone) 0 R ")
        copy.objects[resources] = updated.data(using: .isoLatin1)
    }
    return copy
}

/// The baselines and sizes of the opening slide's title and caption.
func copyMetrics(_ pdf: PDF, page: Int) -> (title: (y: CGFloat, size: CGFloat), caption: (y: CGFloat, size: CGFloat))? {
    guard let (_, contents) = pdf.contents(ofPage: page), let text = String(data: contents, encoding: .isoLatin1) else { return nil }
    let lines = text.matches(of: #/1 0 0 1 [-\d.]+ ([-\d.]+)\s+cm\s+BT\s+(?:[-\d.]+\s+Tc\s+)?([\d.]+) 0 0 [\d.]+/#)
        .compactMap { match -> (CGFloat, CGFloat)? in
            guard let y = Double(match.1), let size = Double(match.2) else { return nil }
            return (CGFloat(y), CGFloat(size))
        }
    guard let largest = lines.map(\.1).max(),
          let title = lines.first(where: { $0.1 == largest }),
          let caption = lines.first(where: { $0.1 < largest }) else { return nil }
    return ((title.0, title.1), (caption.0, caption.1))
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

/// A white tile with a coloured symbol, tilted like the decks' stickers.
func drawSticker(_ sticker: Sticker, page: CGRect, in context: CGContext) {
    let size = page.width * 0.17
    guard let symbol = NSImage(systemSymbolName: sticker.symbol, accessibilityDescription: nil)?
        .withSymbolConfiguration(.init(pointSize: size * 0.5, weight: .bold).applying(.init(paletteColors: [sticker.color])))
    else { fail("no symbol \(sticker.symbol)") }
    context.saveGState()
    context.translateBy(x: page.width * sticker.x, y: page.height * (1 - sticker.y))
    context.rotate(by: sticker.angle * .pi / 180)
    let tile = CGRect(x: -size / 2, y: -size / 2, width: size, height: size)
    context.setShadow(offset: CGSize(width: 0, height: -size * 0.04), blur: size * 0.12, color: CGColor(gray: 0, alpha: 0.3))
    context.addPath(CGPath(roundedRect: tile, cornerWidth: size * 0.24, cornerHeight: size * 0.24, transform: nil))
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fillPath()
    context.setShadow(offset: .zero, blur: 0)
    let fitted = symbol.size.width > symbol.size.height
        ? CGSize(width: size * 0.56, height: size * 0.56 * symbol.size.height / symbol.size.width)
        : CGSize(width: size * 0.56 * symbol.size.width / symbol.size.height, height: size * 0.56)
    let graphics = NSGraphicsContext(cgContext: context, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics
    symbol.draw(in: CGRect(x: -fitted.width / 2, y: -fitted.height / 2, width: fitted.width, height: fitted.height))
    NSGraphicsContext.restoreGraphicsState()
    context.restoreGState()
}

/// A capture in its device frame, clear outside the frame.
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
    context.clip(to: frame.screen)
    context.translateBy(x: frame.screen.midX, y: frame.screen.midY)
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

// MARK: - Composition

func render(_ page: CGPDFPage, then draw: (CGContext, CGRect) -> Void = { _, _ in }, to url: URL) {
    let box = page.getBoxRect(.mediaBox)
    let width = Int(box.width.rounded())
    let height = Int(box.height.rounded())
    guard let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { fail("no context for \(url.lastPathComponent)") }
    context.setFillColor(.white)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.interpolationQuality = .high
    context.translateBy(x: -box.minX, y: -box.minY)
    context.drawPDFPage(page)
    draw(context, CGRect(x: 0, y: 0, width: width, height: height))
    guard let image = context.makeImage(),
          let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)
    else { fail("could not write \(url.lastPathComponent)") }
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
    print("wrote \(url.path.replacingOccurrences(of: scriptDir.path + "/", with: ""))")
}

func document(_ pdf: PDF) -> CGPDFDocument {
    guard let provider = CGDataProvider(data: pdf.data as CFData), let document = CGPDFDocument(provider) else {
        fail("a rewritten PDF does not open")
    }
    return document
}

func framed(_ shot: String, width: Int, height: Int) -> Data {
    guard let raw = loadRaw(shot) else { fail("missing raw capture: Raw/\(shot).png") }
    guard let frame = Frame(width: width, height: height),
          let samples = framedSamples(raw: raw, frame: frame, like: frame.image) else {
        fail("no frame for a \(width)x\(height) screenshot")
    }
    return samples
}

func compose(_ deck: Deck) {
    guard let data = try? Data(contentsOf: deck.template) else { fail("no template: Templates/\(deck.device).pdf") }
    var pdf = PDF(data)
    var placed: Set<Int> = []
    for number in pdf.objects.keys.sorted() {
        guard let (width, height, samples) = imageSamples(pdf, number),
              let index = deck.shots.indices.first(where: { isPlaceholder(samples, width: width, height: height, color: placeholderColor($0)) })
        else { continue }
        pdf.replaceStream(number, with: framed(deck.shots[index].shot, width: width, height: height))
        placed.insert(index)
    }
    let unplaced = Set(deck.shots.indices).subtracting(placed).map { deck.shots[$0].shot }
    if !unplaced.isEmpty { fail("no placeholder for \(unplaced.sorted().joined(separator: ", "))") }

    // The blank slide divides the languages.
    let pages = pdf.pages
    guard let divider = pages.firstIndex(where: { (pdf.contents(ofPage: $0)?.data.count ?? 0) < 256 }) else {
        fail("no blank slide between the languages")
    }
    let rendered = document(pdf)
    for (language, range) in [("en", 0..<divider), ("ja", (divider + 1)..<pages.count)] {
        let directory = scriptDir.appendingPathComponent("\(deck.device)/\(language)")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var number = 0
        func next() -> URL {
            number += 1
            return directory.appendingPathComponent(String(format: "%02d.png", number))
        }
        let opening = pages[range.lowerBound]
        for (position, index) in range.enumerated() {
            guard let page = rendered.page(at: index + 1) else { continue }
            render(page, to: next())
            for slide in deck.newSlides where slide.after == position + 1 {
                guard let copy = slide.copy[language], let metrics = copyMetrics(pdf, page: opening) else {
                    fail("cannot read the opening slide's copy")
                }
                let size = deck.device == "iPhone" ? (1316, 2674) : (1728, 2510)
                let capture = slide.isLandscape ? nil : framed(slide.shot, width: size.0, height: size.1)
                guard let base = newSlideBase(pdf, page: opening, capture: capture),
                      let page = document(base).page(at: range.lowerBound + 1) else {
                    fail("cannot build a slide for \(slide.shot)")
                }
                render(page, then: { context, bounds in
                    if slide.isLandscape { drawLandscapeDevice(slide.shot, page: bounds, in: context) }
                    for sticker in slide.stickers { drawSticker(sticker, page: bounds, in: context) }
                    let width = bounds.width * 0.9
                    drawLine(copy.title, font: "HelveticaNeue-CondensedBlack", japanese: "HiraginoSans-W8",
                             size: metrics.title.size, y: metrics.title.y, width: width, page: bounds, in: context)
                    drawLine(copy.caption, font: "HelveticaNeue-Bold", japanese: "HiraginoSans-W6",
                             size: metrics.caption.size, y: metrics.caption.y, width: width, page: bounds, in: context)
                }, to: next())
            }
        }
    }
}

let arguments = Array(CommandLine.arguments.dropFirst())
if arguments.first == "template" {
    guard arguments.count == 3, let deck = decks.first(where: { $0.device == arguments[1] }) else {
        fail("usage: ./compose.swift template <iPhone|iPad> <exported.pdf>")
    }
    buildTemplate(deck, from: URL(fileURLWithPath: arguments[2]))
} else {
    for deck in decks where arguments.isEmpty || arguments.contains(deck.device) {
        compose(deck)
    }
}
