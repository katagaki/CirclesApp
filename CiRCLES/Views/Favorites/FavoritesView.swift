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
    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(UserSelections.self) var selections
    @Environment(Unifier.self) var unifier
    @Environment(FavoritesDataManager.self) var favoritesDataManager

    @State var favoriteCircles: [String: [ComiketCircle]]?

    @State var isVisitModeOn: Bool = false
    @AppStorage(wrappedValue: false, "Favorites.VisitModeOn") var isVisitModeOnDefault: Bool

    @State var isGroupedByColor: Bool = true
    @AppStorage(wrappedValue: true, "Favorites.GroupByColor") var isGroupedByColorDefault: Bool

    @Namespace var namespace

    var body: some View {
        ZStack(alignment: .center) {
            if let favoriteCircles {
                Group {
                    if isGroupedByColor {
                        ColorGroupedCircleGrid(
                            groups: favoriteCircles,
                            showsOverlayWhenEmpty: false,
                            namespace: namespace
                        ) { circle in
                            if !isVisitModeOn {
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
        .overlay {
            if isVisitModeOn {
                GradientBorder()
                    .ignoresSafeArea(edges: .all)
            }
        }
        .toolbar {
            FavoritesToolbar(isVisitModeOn: $isVisitModeOn, isGroupedByColor: $isGroupedByColor)
        }
        .refreshable {
            await reloadFavorites()
        }
        .onAppear {
            if !favoritesDataManager.isInitialLoadCompleted {
                if favoriteCircles == nil, let favoriteItems = favorites.items {
                    Task.detached {
                        await prepareCircles(using: favoriteItems)
                    }
                }
                isVisitModeOn = isVisitModeOnDefault
                isGroupedByColor = isGroupedByColorDefault
                favoritesDataManager.isInitialLoadCompleted = true
            } else {
                // Load from cache when returning to view
                if let favoriteItems = favorites.items {
                    Task.detached {
                        await prepareCircles(using: favoriteItems)
                    }
                }
            }
        }
        .onChange(of: selections.date) {
            if favoritesDataManager.isInitialLoadCompleted {
                if let favoriteItems = favorites.items {
                    Task.detached {
                        await prepareCircles(using: favoriteItems)
                    }
                }
            }
        }
        .onChange(of: isVisitModeOn) {
            if favoritesDataManager.isInitialLoadCompleted {
                isVisitModeOnDefault = isVisitModeOn
            }
        }
        .onChange(of: isGroupedByColor) {
            if favoritesDataManager.isInitialLoadCompleted {
                isGroupedByColorDefault = isGroupedByColor
            }
        }
        .onChange(of: favorites.items) {
            if let favoriteItems = favorites.items {
                Task.detached {
                    await prepareCircles(using: favoriteItems)
                }
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
        let favoriteCircles = await favoritesDataManager.circles(
            for: favoriteItems,
            dateID: selections.date?.id,
            database: database
        )
        await MainActor.run {
            withAnimation(.smooth.speed(2.0)) {
                self.favoriteCircles = favoriteCircles
            }
        }
    }

    func previousCircle(for circle: ComiketCircle) -> ComiketCircle? {
        if let favoriteCircles {
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
        if let favoriteCircles {
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
