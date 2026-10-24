#if canImport(VisualIntelligence)
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
        guard let image, let text = await CircleFinder.text(in: image) else { return [] }
        return await CircleEntity.entities { fetcher in
            await fetcher.circles(mentionedIn: text)
        }
    }
}
#endif
