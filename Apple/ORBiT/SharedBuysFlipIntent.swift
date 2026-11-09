#if os(iOS) && !targetEnvironment(macCatalyst)
import AppIntents

/// Runs in the app's process, so the Live Activity can flip between this member's
/// remaining items without opening the app.
public struct SharedBuysFlipIntent: LiveActivityIntent {

    public static let title: LocalizedStringResource = "Shared Buys Flip"
    public static let isDiscoverable: Bool = false

    @Parameter(title: "Forward")
    public var isForward: Bool

    public init() {
        isForward = true
    }

    public init(isForward: Bool) {
        self.isForward = isForward
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        SharedBuysIntentBridge.flipHandler?(isForward)
        return .result()
    }
}

@MainActor
public enum SharedBuysIntentBridge {
    public static var flipHandler: ((Bool) -> Void)?
}
#endif
