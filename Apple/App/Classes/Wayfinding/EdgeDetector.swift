import Accelerate

/// Canny edge detection: Gaussian smoothing, Sobel gradients, non-maximum suppression along
/// the gradient direction, then hysteresis so weak edges survive only when they touch a
/// strong one.
nonisolated enum EdgeDetector {

    static func edges(
        gray: [UInt8], width: Int, height: Int, low: Float = 0.08, high: Float = 0.2
    ) -> [Bool] {
        let smooth = blur(gray, width: width, height: height)
        let count = width * height
        var magnitude = [Float](repeating: 0.0, count: count)
        var sector = [UInt8](repeating: 0, count: count)
        var peak: Float = 0.0

        smooth.withUnsafeBufferPointer { pixels in
            for row in 1..<(height - 1) {
                let above = (row - 1) * width
                let here = row * width
                let below = (row + 1) * width
                for column in 1..<(width - 1) {
                    let topLeft = Float(pixels[above + column - 1])
                    let top = Float(pixels[above + column])
                    let topRight = Float(pixels[above + column + 1])
                    let left = Float(pixels[here + column - 1])
                    let right = Float(pixels[here + column + 1])
                    let bottomLeft = Float(pixels[below + column - 1])
                    let bottom = Float(pixels[below + column])
                    let bottomRight = Float(pixels[below + column + 1])
                    let gx = (topRight + 2 * right + bottomRight) - (topLeft + 2 * left + bottomLeft)
                    let gy = (bottomLeft + 2 * bottom + bottomRight) - (topLeft + 2 * top + topRight)
                    let value = (gx * gx + gy * gy).squareRoot()
                    magnitude[here + column] = value
                    if value > peak { peak = value }
                    var angle = atan2(gy, gx) * 180.0 / .pi
                    if angle < 0 { angle += 180.0 }
                    sector[here + column] = UInt8(Int((angle + 22.5) / 45.0) % 4)
                }
            }
        }
        guard peak > 0 else { return [Bool](repeating: false, count: count) }

        let lowThreshold = low * peak
        let highThreshold = high * peak
        let neighbours = [(0, 1), (1, 1), (1, 0), (1, -1)]
        var state = [UInt8](repeating: 0, count: count)
        var stack: [Int] = []
        for row in 1..<(height - 1) {
            for column in 1..<(width - 1) {
                let index = row * width + column
                let value = magnitude[index]
                guard value >= lowThreshold else { continue }
                let (dy, dx) = neighbours[Int(sector[index])]
                let ahead = magnitude[(row + dy) * width + column + dx]
                let behind = magnitude[(row - dy) * width + column - dx]
                guard value >= ahead && value >= behind else { continue }
                if value >= highThreshold {
                    state[index] = 2
                    stack.append(index)
                } else {
                    state[index] = 1
                }
            }
        }

        var result = [Bool](repeating: false, count: count)
        while let index = stack.popLast() {
            if result[index] { continue }
            result[index] = true
            let row = index / width
            let column = index % width
            for dy in -1...1 {
                for dx in -1...1 {
                    let nextRow = row + dy
                    let nextColumn = column + dx
                    guard nextRow >= 0, nextRow < height, nextColumn >= 0, nextColumn < width else { continue }
                    let next = nextRow * width + nextColumn
                    if state[next] > 0 && !result[next] {
                        stack.append(next)
                    }
                }
            }
        }
        return result
    }

    private static func blur(_ gray: [UInt8], width: Int, height: Int) -> [UInt8] {
        let taps: [Int16] = [1, 4, 6, 4, 1]
        var kernel = [Int16]()
        for vertical in taps {
            for horizontal in taps {
                kernel.append(vertical * horizontal)
            }
        }
        var source = gray
        var output = [UInt8](repeating: 0, count: gray.count)
        source.withUnsafeMutableBytes { sourceBytes in
            output.withUnsafeMutableBytes { outputBytes in
                var sourceBuffer = vImage_Buffer(
                    data: sourceBytes.baseAddress, height: vImagePixelCount(height),
                    width: vImagePixelCount(width), rowBytes: width
                )
                var outputBuffer = vImage_Buffer(
                    data: outputBytes.baseAddress, height: vImagePixelCount(height),
                    width: vImagePixelCount(width), rowBytes: width
                )
                vImageConvolve_Planar8(&sourceBuffer, &outputBuffer, nil, 0, 0, kernel, 5, 5, 256, 255,
                                       vImage_Flags(kvImageEdgeExtend))
            }
        }
        return output
    }
}
