//
//  FavoritesView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/04.
//

import SwiftData
import SwiftUI

struct FavoritesView: View {

    @Environment(\.modelContext) var modelContext

    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites
    @Environment(FavoritesCache.self) var favoritesCache
    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(UserSelections.self) var selections
    @Environment(Unifier.self) var unifier

    @AppStorage(wrappedValue: false, "Favorites.VisitModeOn") var isVisitModeOnDefault: Bool
    @AppStorage(wrappedValue: true, "Favorites.GroupByColor") var isGroupedByColorDefault: Bool

    @Namespace var namespace

    var body: some View {
        @Bindable var favoritesCache = favoritesCache
        ZStack(alignment: .center) {
            if let favoriteCircles = favoritesCache.circles {
                Group {
                    if favoritesCache.isGroupedByColor {
                        ColorGroupedCircleGrid(
                            groups: favoriteCircles,
                            showsOverlayWhenEmpty: false,
                            namespace: namespace
                        ) { circle in
                            if !favoritesCache.isVisitModeOn {
                                unifier.append(.namespacedCircleDetail(
                                    circle: circle,
                                    previousCircle: { previousCircle(for: $0) },
                                    nextCircle: { nextCircle(for: $0) },
                                    namespace: namespace
                                ))
                            } else {
                                let circleID = circle.id
                                let eventNumber = planner.activeEventNumber
                                Task.detached {
                                    let actor = VisitActor(modelContainer: sharedModelContainer)
                                    await actor.toggleVisit(circleID: circleID, eventNumber: eventNumber)
                                }
                            }
                        }
                    } else {
                        CircleGrid(
                            circles: favoriteCircles.values.flatMap({ $0 }).sorted(by: { $0.id < $1.id }),
                            showsOverlayWhenEmpty: false,
                            namespace: namespace
                        ) { circle in
                            unifier.append(.namespacedCircleDetail(
                                circle: circle,
                                previousCircle: { previousCircle(for: $0) },
                                nextCircle: { nextCircle(for: $0) },
                                namespace: namespace
                            ))
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("ViewTitle.Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .visitModeStyle($favoritesCache.isVisitModeOn)
        .toolbar {
            FavoritesToolbar()
        }
        .refreshable {
            await reloadFavorites()
        }
        .onAppear {
            if !favoritesCache.isInitialLoadCompleted {
                if favoritesCache.circles == nil,
                    let favoriteItems = favorites.items {
                    Task { await prepareCircles(using: favoriteItems) }
                }
                favoritesCache.isVisitModeOn = isVisitModeOnDefault
                favoritesCache.isGroupedByColor = isGroupedByColorDefault
                favoritesCache.isInitialLoadCompleted = true
            }
        }
        .onChange(of: selections.date) {
            if let favoriteItems = favorites.items {
                Task { await prepareCircles(using: favoriteItems) }
            }
        }
        .onChange(of: favoritesCache.isVisitModeOn) {
            isVisitModeOnDefault = favoritesCache.isVisitModeOn
        }
        .onChange(of: favoritesCache.isGroupedByColor) {
            isGroupedByColorDefault = favoritesCache.isGroupedByColor
        }
        .onChange(of: favorites.items) {
            if let favoriteItems = favorites.items {
                Task { await prepareCircles(using: favoriteItems) }
            }
        }
    }

    func reloadFavorites() async {
        if let token = authenticator.token {
            let actor = FavoritesActor(modelContainer: sharedModelContainer)
            let (items, wcIDMappedItems) = await actor.all(authToken: token)
            await MainActor.run {
                favorites.items = items
                favorites.wcIDMappedItems = wcIDMappedItems
            }
        }
    }

    func prepareCircles(using favoriteItems: [UserFavorites.Response.FavoriteItem]) async {
        let favoriteCircleIdentifiers = await FavoritesCache.mapped(using: favoriteItems)
        await MainActor.run {
            var favoriteCircles: [String: [ComiketCircle]] = [:]
            for colorKey in favoriteCircleIdentifiers.keys.sorted() {
                if let circleIdentifiers = favoriteCircleIdentifiers[colorKey] {
                    var circles = database.circles(circleIdentifiers)
                    circles.sort(by: {$0.id < $1.id})
                    if let selectedDate = selections.date {
                        favoriteCircles[String(colorKey)] = circles.filter({
                            $0.day == selectedDate.id
                        })
                    } else {
                        favoriteCircles[String(colorKey)] = circles
                    }
                }
            }
            withAnimation(.smooth.speed(2.0)) {
                self.favoritesCache.circles = favoriteCircles
            }
        }
    }

    func previousCircle(for circle: ComiketCircle) -> ComiketCircle? {
        if let favoriteCircles = favoritesCache.circles {
            let colors = WebCatalogColor.allCases.map({String($0.rawValue)})
            for colorIndex in 0..<colors.count {
                if let circles = favoriteCircles[colors[colorIndex]],
                   let index = circles.firstIndex(of: circle) {
                    if index > 0 {
                        return circles[index - 1]
                    } else {
                        return nil
                    }
                }
            }
        }
        return nil
    }

    func nextCircle(for circle: ComiketCircle) -> ComiketCircle? {
        if let favoriteCircles = favoritesCache.circles {
            let colors = WebCatalogColor.allCases.map({String($0.rawValue)})
            for colorIndex in 0..<colors.count {
                if let circles = favoriteCircles[colors[colorIndex]],
                   let index = circles.firstIndex(of: circle) {
                    if index < circles.count - 1 {
                        return circles[index + 1]
                    } else {
                        return nil
                    }
                }
            }
        }
        return nil
    }
}
