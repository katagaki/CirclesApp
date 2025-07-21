//
//  MapView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/18.
//

import Komponents
import SwiftData
import SwiftUI

struct MapView: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @EnvironmentObject var navigator: Navigator<TabType, ViewPath>
    @Environment(Orientation.self) var orientation
    @Environment(Database.self) var database

    @Query(sort: [SortDescriptor(\ComiketDate.id, order: .forward)])
    var dates: [ComiketDate]

    @Query(sort: [SortDescriptor(\ComiketMap.id, order: .forward)])
    var maps: [ComiketMap]

    @Namespace var mapNamespace

    var body: some View {
        NavigationStack(path: $navigator[.map]) {
            InteractiveMap(namespace: mapNamespace)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("ViewTitle.Map")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: ViewPath.self) { viewPath in
                    switch viewPath {
                    case .circlesDetail(let circle): CircleDetailView(circle: circle)
                            .automaticNavigationTransition(
                                id: "Layout.\(circle.blockID).\(circle.spaceNumber)",
                                in: mapNamespace
                            )
                    default: Color.clear
                    }
                }
        }
    }
}
