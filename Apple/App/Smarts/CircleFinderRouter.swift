import Foundation
import Observation

/// Hands circles found outside the app's views — by an App Intent, Visual Intelligence or
/// a shared link — over to the views, which may not exist yet when the request arrives.
@MainActor
@Observable
final class CircleFinderRouter {

    static let shared = CircleFinderRouter()

    /// A circle to open, as a `CircleEntity` identifier.
    var pendingCircle: String?

    /// Text to look for circles in, shown as a list of the circles found.
    var pendingText: String?

    private init() { }
}
