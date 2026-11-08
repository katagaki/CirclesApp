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

/// The way ahead is closed. The app seals that aisle off and plans a detour.
public struct RouteBlockedIntent: LiveActivityIntent {

    public static let title: LocalizedStringResource = "Route Blocked"
    public static let isDiscoverable: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        RouteIntentBridge.blockedHandler?()
        return .result()
    }
}

@MainActor
public enum RouteIntentBridge {
    public static var handler: ((Bool) -> Void)?
    public static var blockedHandler: (() -> Void)?
}

public struct ORBiTAppIntents: AppIntentsPackage {}
#endif
