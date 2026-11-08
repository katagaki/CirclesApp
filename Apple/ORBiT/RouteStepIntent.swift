#if os(iOS) && !targetEnvironment(macCatalyst)
import AppIntents

/// Runs in the app's process, so the Live Activity's buttons can move the route along
/// without opening the app.
public struct RouteStepIntent: LiveActivityIntent {

    public static let title: LocalizedStringResource = "Route Step"
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
        RouteIntentBridge.handler?(isForward)
        return .result()
    }
}

@MainActor
public enum RouteIntentBridge {
    public static var handler: ((Bool) -> Void)?
}

public struct ORBiTAppIntents: AppIntentsPackage {}
#endif
