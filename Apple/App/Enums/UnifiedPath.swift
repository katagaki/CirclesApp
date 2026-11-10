import Foundation
import SwiftUI
import AXiS

enum UnifiedPath: Identifiable, CaseIterable, Equatable, Hashable, RawRepresentable {
    case map
    case circles
    case favorites
    case buys
    case navi
    case my
    case moreEventData
    case moreBackup
    case moreAttributions
    case routePriority
    case circleDetail(
        circle: ComiketCircle
    )
    case namespacedCircleDetail(
        circle: ComiketCircle,
        previousCircle: ((ComiketCircle) -> ComiketCircle?)? = nil,
        nextCircle: ((ComiketCircle) -> ComiketCircle?)? = nil,
        namespace: Namespace.ID
    )

    nonisolated(unsafe) static let allCases: [UnifiedPath] = []

    typealias RawValue = String

    init?(rawValue _: String) { return nil }
    var id: String { return self.identifier() }
    var rawValue: String { return self.id }

    func identifier() -> String {
        return switch self {
        case .map: "Map"
        case .circles: "Circles"
        case .favorites: "Favorites"
        case .buys: "Buys"
        case .navi: "Navi"
        case .my: "My"
        case .moreEventData: "More.EventData"
        case .moreBackup: "More.Backup"
        case .moreAttributions: "More.Attributions"
        case .routePriority: "Route.Priority"
        case .circleDetail(let circle): "Circles.\(circle.id)"
        case .namespacedCircleDetail(
            let circle, _, _, _
        ): "Circles.\(circle.id)"
        }
    }

    @MainActor
    @ViewBuilder
    func view() -> some View {
        switch self {
        case .map: MapView()
        case .circles: CatalogView()
        case .favorites: FavoritesView()
        case .buys: BuysView()
        case .navi: NaviView()
        case .my: MyView()
        case .moreEventData: EventDataView()
        case .moreBackup: BackupView()
        case .moreAttributions: MoreLicensesView()
        case .routePriority: RoutePriorityView()
        case .circleDetail(let circle):
            CircleDetailView(circle: circle)
        case .namespacedCircleDetail(
            let circle, let previousCircle, let nextCircle, _
        ):
            CircleDetailView(
                circle: circle,
                previousCircle: previousCircle,
                nextCircle: nextCircle
            )
        }
    }
}
