#if canImport(VisualIntelligence) && !targetEnvironment(macCatalyst)
import AppIntents
import CoreImage
import VisualIntelligence

/// Lets Visual Intelligence find circles in whatever is on screen or in front of the
/// camera, by reading the placements in it.
struct CircleVisualSearchQuery: IntentValueQuery {

    func values(for input: SemanticContentDescriptor) async throws -> [CircleEntity] {
        guard let pixelBuffer = input.pixelBuffer else { return [] }
        let image: CGImage? = pixelBuffer.withUnsafeBuffer { buffer in
            let ciImage = CIImage(cvPixelBuffer: buffer)
            return CIContext().createCGImage(ciImage, from: ciImage.extent)
        }
        guard let image else { return [] }
        let lines = await CircleFinder.lines(in: image)
        guard !lines.isEmpty else { return [] }
        return await CircleEntity.entities { fetcher in
            await fetcher.circles(seenIn: lines)
        }
    }
}
#endif
