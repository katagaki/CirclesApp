//
//  FavoritesView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/04.
//

import Komponents
import SwiftData
import SwiftUI

struct FavoritesView: View {

    @Environment(\.modelContext) var modelContext

    @EnvironmentObject var navigator: Navigator
    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database
    @Environment(Planner.self) var planner

    @Query var visits: [CirclesVisitEntry]

    @State var favoriteCircles: [String: [ComiketCircle]]?
    @State var isVisitMode: Bool = false

    @Namespace var favoritesNamespace

    var body: some View {
        NavigationStack(path: $navigator[.favorites]) {
            ZStack(alignment: .center) {
                if let favoriteCircles {
                    ColorGroupedCircleGrid(
                        groups: favoriteCircles,
                        showsOverlayWhenEmpty: false,
                        namespace: favoritesNamespace
                    ) { circle in
                        if !isVisitMode {
                            navigator.push(.circlesDetail(circle: circle), for: .favorites)
                        } else {
                            let existingVisits = visits.filter({
                                $0.circleID == circle.id && $0.eventNumber == planner.activeEventNumber
                            })
                            if existingVisits.isEmpty {
                                modelContext.insert(
                                    CirclesVisitEntry(eventNumber: planner.activeEventNumber,
                                                      circleID: circle.id,
                                                      visitDate: .now)
                                )
                            } else {
                                for visit in existingVisits {
                                    modelContext.delete(visit)
                                }
                            }
                        }
                    }
                       .overlay {
                           if favoriteCircles.isEmpty {
                               ContentUnavailableView(
                                   "Favorites.NoFavorites",
                                   systemImage: "star.leadinghalf.filled",
                                   description: Text("Favorites.NoFavorites.Description")
                               )
                           }
                       }
                } else {
                    ProgressView("Favorites.Loading")
                        .frame(maxHeight: .infinity)
                }
            }
            .navigationTitle("ViewTitle.Favorites")
            .toolbarBackground(.automatic, for: .navigationBar)
            .toolbarBackground(.hidden, for: .tabBar)
            .overlay {
                if isVisitMode {
                    Rectangle()
                        .fill(
                            MeshGradient(
                                width: 6,
                                height: 8,
                                points: [
                                    [0.0, 0.0], [0.2, 0.0], [0.4, 0.0], [0.6, 0.0], [0.8, 0.0], [1.0, 0.0],
                                    [0.0, 0.1], [0.1, 0.09], [0.15, 0.08], [0.85, 0.08], [0.9, 0.09], [1.0, 0.1],
                                    [0.0, 0.15], [0.1, 0.15], [0.15, 0.15], [0.85, 0.15], [0.9, 0.15], [1.0, 0.15],
                                    [0.0, 0.85], [0.1, 0.85], [0.15, 0.85], [0.85, 0.85], [0.9, 0.85], [1.0, 0.85],
                                    [0.0, 0.9], [0.1, 0.91], [0.15, 0.92], [0.85, 0.92], [0.9, 0.91], [1.0, 0.9],
                                    [0.0, 1.0], [0.2, 1.0], [0.4, 1.0], [0.6, 1.0], [0.8, 1.0], [1.0, 1.0]
                                ],
                                colors: [
                                    .accent, .accent, .accent, .accent, .accent, .accent,
                                    .accent, .clear, .clear, .clear, .clear, .accent,
                                    .accent, .clear, .clear, .clear, .clear, .accent,
                                    .accent, .clear, .clear, .clear, .clear, .accent,
                                    .accent, .clear, .clear, .clear, .clear, .accent,
                                    .accent, .accent, .accent, .accent, .accent, .accent
                                ],
                                background: .clear
                            )
                        )
                        .allowsHitTesting(false)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                BarAccessory(placement: .bottom) {
                    FavoritesToolbar(isVisitMode: $isVisitMode)
                }
            }
            .refreshable {
                await reloadFavorites()
            }
            .onAppear {
                if authenticator.onlineState == .offline {
                    favoriteCircles = [:]
                } else {
                    if favoriteCircles == nil, let favoriteItems = favorites.items {
                        Task.detached {
                            await prepareCircles(using: favoriteItems)
                        }
                    }
                }
            }
            .onChange(of: favorites.items) { _, _ in
                if let favoriteItems = favorites.items {
                    Task.detached {
                        await prepareCircles(using: favoriteItems)
                    }
                }
            }
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .circlesDetail(let circle):
                    CircleDetailView(circle: circle)
                        .automaticNavigationTransition(id: circle.id, in: favoritesNamespace)
                default: Color.clear
                }
            }
        }
    }

    func reloadFavorites() async {
        if let token = authenticator.token {
            let actor = FavoritesActor()
            let (items, wcIDMappedItems) = await actor.all(authToken: token)
            await MainActor.run {
                favorites.items = items
                favorites.wcIDMappedItems = wcIDMappedItems
            }
        }
    }

    func prepareCircles(using favoriteItems: [UserFavorites.Response.FavoriteItem]) async {
        let favoriteItemsSorted: [Int: [UserFavorites.Response.FavoriteItem]] = favoriteItems.reduce(
            into: [Int: [UserFavorites.Response.FavoriteItem]]()
        ) { partialResult, favoriteItem in
            partialResult[favoriteItem.favorite.color.rawValue, default: []].append(favoriteItem)
        }

        let actor = DataFetcher(modelContainer: sharedModelContainer)
        var favoriteCircleIdentifiers: [Int: [PersistentIdentifier]] = [:]
        for colorKey in favoriteItemsSorted.keys {
            if let favoriteItems = favoriteItemsSorted[colorKey] {
                favoriteCircleIdentifiers[colorKey] = await actor.circles(forFavorites: favoriteItems)
            }
        }
        await MainActor.run {
            var favoriteCircles: [String: [ComiketCircle]] = [:]
            for colorKey in favoriteCircleIdentifiers.keys.sorted() {
                if let circleIdentifiers = favoriteCircleIdentifiers[colorKey] {
                    var circles = database.circles(circleIdentifiers)
                    circles.sort(by: {$0.id < $1.id})
                    favoriteCircles[String(colorKey)] = circles
                }
            }
            withAnimation(.snappy.speed(2.0)) {
                self.favoriteCircles = favoriteCircles
            }
        }
    }
}
