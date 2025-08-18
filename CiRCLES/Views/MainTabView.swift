//
//  MainTabView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/18.
//

import Komponents
import StoreKit
import SwiftUI
import SwiftData
import TipKit

struct MainTabView: View {

    @Environment(\.requestReview) var requestReview
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var navigator: Navigator<TabType, ViewPath>
    @Environment(Events.self) var planner

    @State var isReloadingData: Bool = false

    @AppStorage(wrappedValue: false, "Database.Initialized") var isDatabaseInitialized: Bool
    @AppStorage(wrappedValue: false, "Review.IsPrompted", store: .standard) var hasReviewBeenPrompted: Bool
    @AppStorage(wrappedValue: 0, "Review.LaunchCount", store: .standard) var launchCount: Int

    @Namespace var loadingNamespace

    var body: some View {
        TabView(selection: $navigator.selectedTab) {
            Tab("Tab.Map", systemImage: "map.fill", value: .map) {
                MapView()
            }
            Tab("Tab.Circles", systemImage: "square.grid.3x3.fill", value: .circles, role: .search) {
                CatalogView()
            }
            Tab("Tab.Favorites", systemImage: "star.fill", value: .favorites) {
                FavoritesView()
            }
            .hidden(!planner.isActiveEventLatest)
            Tab("Tab.My", image: "TabIcon.My", value: .my) {
                MyView()
            }
            Tab("Tab.More", systemImage: "ellipsis", value: .more) {
                MoreView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            UnifiedControl()
        }
        .task {
            prepareTipKit()
            showReviewPromptIfLaunchedEnoughTimes()
        }
        .authenticated()
        #if DEBUG
        .debugOverlay()
        #endif
    }

    func prepareTipKit() {
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }

    func showReviewPromptIfLaunchedEnoughTimes() {
        launchCount += 1
        if launchCount > 2 && !hasReviewBeenPrompted {
            requestReview()
            hasReviewBeenPrompted = true
        }
    }
}
