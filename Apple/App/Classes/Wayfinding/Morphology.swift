import Accelerate

/// Binary masks are one byte per pixel, 0 or 255, so vImage's min and max filters act as
/// erosion and dilation with a rectangular structuring element.
nonisolated enum Morphology {

    static func erode(_ mask: [UInt8], width: Int, height: Int, kernel: (width: Int, height: Int)) -> [UInt8] {
        filter(mask, width: width, height: height, kernel: kernel, usesMinimum: true)
    }

    static func dilate(_ mask: [UInt8], width: Int, height: Int, kernel: (width: Int, height: Int)) -> [UInt8] {
        filter(mask, width: width, height: height, kernel: kernel, usesMinimum: false)
    }

    static func open(_ mask: [UInt8], width: Int, height: Int, size: Int) -> [UInt8] {
        let eroded = erode(mask, width: width, height: height, kernel: (size, size))
        return dilate(eroded, width: width, height: height, kernel: (size, size))
    }

    private static func filter(
        _ mask: [UInt8], width: Int, height: Int, kernel: (width: Int, height: Int), usesMinimum: Bool
    ) -> [UInt8] {
        var source = mask
        var output = [UInt8](repeating: 0, count: mask.count)
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
                let kernelHeight = vImagePixelCount(kernel.height | 1)
                let kernelWidth = vImagePixelCount(kernel.width | 1)
                if usesMinimum {
                    vImageMin_Planar8(&sourceBuffer, &outputBuffer, nil, 0, 0,
                                      kernelHeight, kernelWidth, vImage_Flags(kvImageNoFlags))
                } else {
                    vImageMax_Planar8(&sourceBuffer, &outputBuffer, nil, 0, 0,
                                      kernelHeight, kernelWidth, vImage_Flags(kvImageNoFlags))
                }
            }
        }
        return output
    }
}
