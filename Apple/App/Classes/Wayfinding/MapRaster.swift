import CoreGraphics

/// The map image split into the ink classes the wayfinder cares about. Block letters are
/// green and float over the aisles, so they are painted out before edges are looked for.
nonisolated struct MapRaster {

    let dark: [UInt8]
    let fillOrDark: [UInt8]
    let neutralGray: [UInt8]
    let gray: [UInt8]

    init?(image: CGImage) {
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 255, count: width * height * 4)
        let didDraw = pixels.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(
                data: bytes.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ) else { return false }
            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard didDraw else { return nil }

        var dark = [UInt8](repeating: 0, count: width * height)
        var fillOrDark = [UInt8](repeating: 0, count: width * height)
        var neutralGray = [UInt8](repeating: 255, count: width * height)
        var plainGray = [UInt8](repeating: 255, count: width * height)
        pixels.withUnsafeBufferPointer { rgba in
            for index in 0..<(width * height) {
                let red = Int(rgba[index * 4])
                let green = Int(rgba[index * 4 + 1])
                let blue = Int(rgba[index * 4 + 2])
                let gray = (299 * red + 587 * green + 114 * blue) / 1000
                let saturation = max(red, green, blue) - min(red, green, blue)
                let isLabel = saturation > 60 && green > red && green > blue
                let isDark = gray < 140 && saturation < 40
                let isFill = gray >= 140 && gray < 245 && saturation < 25
                dark[index] = isDark ? 255 : 0
                fillOrDark[index] = (isDark || isFill) ? 255 : 0
                neutralGray[index] = isLabel ? 255 : UInt8(gray)
                plainGray[index] = UInt8(gray)
            }
        }
        self.dark = dark
        self.fillOrDark = fillOrDark
        self.neutralGray = neutralGray
        self.gray = plainGray
    }
}
