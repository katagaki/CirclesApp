//
//  UnifiedPath.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/08/18.
//

import Foundation
import Komponents
import SwiftUI

enum UnifiedPath: Identifiable, CaseIterable, Equatable, Hashable, RawRepresentable {
    case map
    case circles
    case favorites
    case my
    case more
    case moreDBAdmin
    case moreAttributions
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

    init?(rawValue: String) { return nil }
    var id: String { return self.identifier() }
    var rawValue: String { return self.identifier() }

    func identifier() -> String {
        return switch self {
        case .map: "Map"
        case .circles: "Circles"
        case .favorites: "Favorites"
        case .my: "My"
        case .more: "More"
        case .moreDBAdmin: "More.DBAdmin"
        case .moreAttributions: "More.Attributions"
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
        case .my: MyView()
        case .more: MoreView()
        case .moreDBAdmin: MoreDatabaseAdministratiion()
        case .moreAttributions: MoreView()
        case .circleDetail(let circle):
            CircleDetailView(circle: circle)
        case .namespacedCircleDetail(
            let circle, let previousCircle, let nextCircle, let namespace
        ):
            CircleDetailView(
                circle: circle,
                previousCircle: previousCircle,
                nextCircle: nextCircle
            )
            .navigationTransition(.zoom(sourceID: circle.id, in: namespace))
        }
    }
}
