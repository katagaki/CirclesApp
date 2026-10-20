import AppIntents
import Foundation

/// Opens a circle's details in the app. Also what Visual Intelligence runs when a circle it
/// found is tapped.
struct OpenCircleIntent: OpenIntent {

    static let title: LocalizedStringResource = "Intents.OpenCircle"

    @Parameter(title: "Intents.Circle")
    var target: CircleEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        CircleFinderRouter.shared.pendingCircle = target.id
        return .result()
    }
}

/// Finds the circles a post or a screenshot of one mentions, such as the placement notice
/// circle.ms sends: `火曜日 東地区 “マ”ブロック－64b`.
struct FindCirclesIntent: AppIntent {

    static let title: LocalizedStringResource = "Intents.FindCircles"
    static let description = IntentDescription("Intents.FindCircles.Description")

    @Parameter(title: "Intents.FindCircles.Text", inputConnectionBehavior: .connectToPreviousIntentResult)
    var text: String?

    @Parameter(title: "Intents.FindCircles.Image", supportedContentTypes: [.image])
    var image: IntentFile?

    func perform() async throws -> some ReturnsValue<[CircleEntity]> {
        var texts: [String] = []
        if let text {
            texts.append(text)
        }
        if let image, let recognized = await CircleFinder.text(in: image.data) {
            texts.append(recognized)
        }
        let combined = texts.joined(separator: "\n")
        let circles = await CircleEntity.entities { fetcher in
            await CircleFinder.circles(mentionedIn: combined, using: fetcher)
        }
        return .result(value: circles)
    }
}
