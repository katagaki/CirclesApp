#!/usr/bin/env swift

// Lays the raw captures into the Keynote designs and writes the App Store screenshots.
// Usage: ./compose.swift           (both iPhone and iPad)
//        ./compose.swift iPad
//
// The Keynote decks in Assets/ are the design. Each deck is exported to PDF, and every
// screenshot placed in it is found by matching its pixels to the image files inside the
// deck, then swapped for a fresh capture from Raw/ in a device frame from Frames/. The
// slides before the deck's blank slide are English and the ones after it are Japanese.

import AppKit
import ImageIO

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let assetsDir = scriptDir.deletingLastPathComponent().deletingLastPathComponent()
let requestedDevices = Set(CommandLine.arguments.dropFirst())

struct Deck {
    let device: String
    let keynote: String
    /// The deck's image files, by name without the suffix Keynote adds, mapped to the
    /// capture that replaces them, as `<device>/<shot>`.
    let shots: [String: String]
}

let decks = [
    Deck(device: "iPhone", keynote: "App Store 26+ (6.5inch iPhone).key", shots: [
        "CiRCLES 26+ 1": "iPhone/01-map",
        "CiRCLES 26+ 2": "iPhone/02-grid",
        "CiRCLES 26+ 3": "iPhone/03-list",
        "CiRCLES 26+ 4": "iPhone/04-detail",
        "CiRCLES 26+ 5": "iPhone/05-translate",
        "CiRCLES 26+ 6": "iPhone/06-links",
        "CiRCLES 26+ 7": "iPhone/07-context-menu",
        "CiRCLES 26+ 8": "iPhone/08-favorite",
        "CiRCLES 26+ 9": "iPhone/09-my",
        "CiRCLES 26+ 10": "iPhone/10-more",
        "CiRCLES 26+ 12": "iPhone/11-visits",
    ]),
    Deck(device: "iPad", keynote: "App Store 26+ (12.9inch iPad Pro).key", shots: [
        "CiRCLES iPad 26+ 01": "iPad/01-map",
        "CiRCLES iPad 26+ 02": "iPad/02-list",
        "CiRCLES iPad 26+ 03": "iPad/03-grid",
        "CiRCLES iPad 26+ 04": "iPad/04-detail",
        "CiRCLES 26+ 5": "iPhone/05-translate",
        "CiRCLES iPad 26+ 06": "iPad/06-links",
        "CiRCLES iPad 26+ 07": "iPad/07-context-menu",
        "CiRCLES iPad 26+ 08": "iPad/08-favorite",
        "CiRCLES iPad 26+ 09": "iPad/11-visits",
        "CiRCLES iPad 26+ 10a": "iPad/09-my",
        "CiRCLES iPad 26+ 11": "iPad/10-more",
    ]),
]

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(1)
}

@discardableResult
func run(_ tool: String, _ arguments: [String], failing: Bool = true) -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: tool)
    process.arguments = arguments
    process.standardOutput = FileHandle.nullDevice
    do { try process.run() } catch { fail("could not run \(tool): \(error)") }
    process.waitUntilExit()
    if failing, process.terminationStatus != 0 { fail("\(tool) failed") }
    return process.terminationStatus == 0
}

// MARK: - Keynote

/// Exports a copy of the deck, so Keynote never holds the original open.
func exportPDF(_ deck: Deck, into work: URL) -> URL {
    let copy = work.appendingPathComponent("deck.key")
    let pdf = work.appendingPathComponent("deck.pdf")
    try? FileManager.default.copyItem(at: assetsDir.appendingPathComponent(deck.keynote), to: copy)
    // AppleScript cannot start Keynote Creator Studio itself, so it is opened with the
    // deck; opened empty, it would wait on its file picker.
    run("/usr/bin/open", ["-g", "-b", "com.apple.Keynote", copy.path])
    for _ in 0..<20 where !run("/usr/bin/osascript", ["-e", "tell application id \"com.apple.Keynote\" to get name"], failing: false) {
        Thread.sleep(forTimeInterval: 1)
    }
    run("/usr/bin/osascript", [
        "-e", "on run argv",
        "-e", "tell application id \"com.apple.Keynote\"",
        "-e", "with timeout of 900 seconds",
        "-e", "set d to open POSIX file (item 1 of argv)",
        "-e", "export d to POSIX file (item 2 of argv) as PDF",
        "-e", "close d saving no",
        "-e", "end timeout",
        "-e", "end tell",
        "-e", "end run",
        copy.path, pdf.path,
    ])
    run("/usr/bin/ditto", ["-x", "-k", copy.path, work.path])
    return pdf
}

/// The deck's own image files, keyed by name, with Keynote's `-1234` suffix removed.
func deckImages(in work: URL, named names: Set<String>) -> [String: CGImage] {
    let data = work.appendingPathComponent("Data")
    let files = (try? FileManager.default.contentsOfDirectory(atPath: data.path)) ?? []
    var images: [String: CGImage] = [:]
    for file in files where !file.contains("-small-") {
        let name = file.replacingOccurrences(of: #"-\d+\.png$"#, with: "", options: .regularExpression)
        guard names.contains(name),
              let source = CGImageSourceCreateWithURL(data.appendingPathComponent(file) as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { continue }
        images[name] = image
    }
    return images
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

    /// Replaces a stream's contents, stored uncompressed.
    mutating func replaceStream(_ number: Int, with samples: Data) {
        var dictionary = header(number)
        guard let open = dictionary.range(of: "<<"), let close = dictionary.range(of: ">>", options: .backwards) else {
            return
        }
        var entries = String(dictionary[open.upperBound..<close.lowerBound])
        entries = entries.replacingOccurrences(of: #"/Length\s+\d+"#, with: "/Length \(samples.count)", options: .regularExpression)
        entries = entries.replacingOccurrences(of: #"/Filter\s*/FlateDecode"#, with: "", options: .regularExpression)
        dictionary = "\(number) 0 obj\n<<\(entries)>>\nstream\n"
        var object = Data(dictionary.utf8)
        object.append(samples)
        object.append(Data("\nendstream\nendobj\n".utf8))
        objects[number] = object
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

/// Blanks the clocks laid over the phones in the decks, and the patches behind them. They
/// hid the times in older captures, which now all read 9:41.
///
/// Each Keynote item is its own marked-content block. A clock is a text box, drawn in
/// Keynote's `/Tc` fonts, whose text starts with a time; its patch is the plain filled
/// rectangle just before it. Only their marks are dropped, so the graphics state stays
/// balanced.
func removingClocks(from contents: Data) -> Data? {
    guard let text = String(data: contents, encoding: .isoLatin1) else { return nil }
    guard let marker = try? NSRegularExpression(pattern: #"/P << /MCID \d+ >>\s*BDC"#) else { return nil }
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

// MARK: - Composition

func writePNG(_ page: CGPDFPage, to url: URL) {
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
    guard let image = context.makeImage(),
          let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)
    else { fail("could not write \(url.lastPathComponent)") }
    CGImageDestinationAddImage(destination, image, nil)
    CGImageDestinationFinalize(destination)
    print("wrote \(url.path.replacingOccurrences(of: scriptDir.path + "/", with: ""))")
}

func compose(_ deck: Deck) {
    // Keynote is sandboxed and is not let into the per-user temporary directory.
    let work = URL(fileURLWithPath: "/tmp/circles-compose-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: work) }

    guard let exported = try? Data(contentsOf: exportPDF(deck, into: work)) else { fail("no PDF for \(deck.keynote)") }
    var pdf = PDF(exported)
    let images = deckImages(in: work, named: Set(deck.shots.keys))
    var found: Set<String> = []
    var missing: Set<String> = []

    for number in pdf.objects.keys.sorted() {
        let header = pdf.header(number)
        guard header.range(of: #"/Subtype\s*/Image"#, options: .regularExpression) != nil,
              let width = pdf.integer("Width", in: header), let height = pdf.integer("Height", in: header),
              width >= 600, height >= 600,
              let stream = pdf.stream(number), let decoded = inflate(stream),
              let (name, original) = images
                  .filter({ $0.value.width == width && $0.value.height == height })
                  .compactMap({ image in difference(decoded, image.value).map { (image, $0) } })
                  .filter({ $0.1 < 400 }).min(by: { $0.1 < $1.1 })?.0,
              let shot = deck.shots[name] else { continue }
        guard let raw = loadRaw(shot) else {
            missing.insert(shot)
            continue
        }
        guard let frame = Frame(width: width, height: height),
              let samples = framedSamples(raw: raw, frame: frame, like: original) else {
            fail("no frame for a \(width)x\(height) screenshot")
        }
        pdf.replaceStream(number, with: samples)
        found.insert(name)
    }
    for number in pdf.objects.keys.sorted() {
        guard pdf.header(number).range(of: #"/Type\s*/Page[^s]"#, options: .regularExpression) != nil,
              let contents = pdf.integer("Contents", in: pdf.header(number).replacingOccurrences(of: " 0 R", with: "")),
              let stream = pdf.stream(contents), let decoded = inflate(stream),
              let cleaned = removingClocks(from: decoded) else { continue }
        pdf.replaceStream(contents, with: cleaned)
    }
    if !missing.isEmpty { fail("missing raw captures: \(missing.sorted().joined(separator: ", "))") }
    let unused = Set(deck.shots.keys).subtracting(found)
    if !unused.isEmpty { print("not placed in \(deck.keynote): \(unused.sorted().joined(separator: ", "))") }

    guard let provider = CGDataProvider(data: pdf.data as CFData),
          let document = CGPDFDocument(provider) else { fail("the rewritten PDF does not open") }
    var language = "en"
    var index = 0
    for pageNumber in 1...document.numberOfPages {
        guard let page = document.page(at: pageNumber) else { continue }
        // The blank slide divides the languages.
        if page.dictionary.flatMap({ dictionary -> Int? in
            var contents: CGPDFStreamRef?
            guard CGPDFDictionaryGetStream(dictionary, "Contents", &contents), let contents else { return nil }
            var format = CGPDFDataFormat.raw
            return (CGPDFStreamCopyData(contents, &format) as Data?)?.count
        }) ?? 0 < 256 {
            language = "ja"
            index = 0
            continue
        }
        index += 1
        let directory = scriptDir.appendingPathComponent("\(deck.device)/\(language)")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        writePNG(page, to: directory.appendingPathComponent(String(format: "%02d.png", index)))
    }
}

for deck in decks where requestedDevices.isEmpty || requestedDevices.contains(deck.device) {
    compose(deck)
}
