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

    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(UserSelections.self) var selections
    @Environment(Sheets.self) var sheets

    @State var favoriteCircles: [String: [ComiketCircle]]?

    @Query(sort: [SortDescriptor(\ComiketDate.id, order: .forward)])
    var dates: [ComiketDate]

    @State var isVisitModeOn: Bool = false
    @AppStorage(wrappedValue: false, "Favorites.VisitModeOn") var isVisitModeOnDefault: Bool

    @State var isGroupedByColor: Bool = true
    @AppStorage(wrappedValue: true, "Favorites.GroupByColor") var isGroupedByColorDefault: Bool

    @State var isInitialLoadCompleted: Bool = false

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
                                sheets.append(.namespacedCircleDetail(
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
                            sheets.append(.namespacedCircleDetail(
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
        .safeAreaInset(edge: .bottom, spacing: 0.0) {
            FavoritesToolbar(
                isVisitModeOn: $isVisitModeOn,
                isGroupedByColor: $isGroupedByColor
            )
        }
        .refreshable {
            await reloadFavorites()
        }
        .onAppear {
            if !isInitialLoadCompleted {
                if favoriteCircles == nil, let favoriteItems = favorites.items {
                    Task.detached {
                        await prepareCircles(using: favoriteItems)
                    }
                }
                isVisitModeOn = isVisitModeOnDefault
                isGroupedByColor = isGroupedByColorDefault
                isInitialLoadCompleted = true
            }
        }
        .onChange(of: selections.date) { _, _ in
            if isInitialLoadCompleted {
                if let favoriteItems = favorites.items {
                    Task.detached {
                        await prepareCircles(using: favoriteItems)
                    }
                }
            }
        }
        .onChange(of: isVisitModeOn) { _, _ in
            if isInitialLoadCompleted {
                isVisitModeOnDefault = isVisitModeOn
            }
        }
        .onChange(of: isGroupedByColor) { _, _ in
            if isInitialLoadCompleted {
                isGroupedByColorDefault = isGroupedByColor
            }
        }
        .onChange(of: favorites.items) { _, _ in
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
