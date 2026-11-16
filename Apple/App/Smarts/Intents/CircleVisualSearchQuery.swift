#if canImport(VisualIntelligence) && !targetEnvironment(macCatalyst)
import AppIntents
import CoreImage
import VisualIntelligence

/// Lets Visual Intelligence find circles in whatever is on screen, such as a screenshot of a
/// post on X, by reading the placements and names in it.
struct CircleVisualSearchQuery: IntentValueQuery {

    func values(for input: SemanticContentDescriptor) async throws -> [CircleEntity] {
        let image: CGImage? = input.pixelBuffer?.withUnsafeBuffer { buffer in
            let ciImage = CIImage(cvPixelBuffer: buffer)
            return CIContext().createCGImage(ciImage, from: ciImage.extent)
        }
        guard let image else { return [CircleEntity(nothingFound: .unreadableImage)] }
        guard CircleFinder.catalog() != nil else { return [CircleEntity(nothingFound: .noCatalog)] }
        let lines = await CircleFinder.lines(in: image)
        guard !lines.isEmpty else { return [CircleEntity(nothingFound: .noText)] }
        let circles = await CircleEntity.entities { fetcher in
            await fetcher.circles(seenIn: lines)
        }
        return circles.isEmpty ? [CircleEntity(nothingFound: .noCircles)] : circles
    }
}
#endif
