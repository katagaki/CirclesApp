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

    @EnvironmentObject var navigator: Navigator<TabType, ViewPath>
    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database
    @Environment(Planner.self) var planner

    @State var favoriteCircles: [String: [ComiketCircle]]?

    @Query(sort: [SortDescriptor(\ComiketDate.id, order: .forward)])
    var dates: [ComiketDate]

    @State var selectedDate: ComiketDate?
    @AppStorage(wrappedValue: 0, "Favorites.SelectedDateID") var selectedDateID: Int

    @State var isVisitModeOn: Bool = false
    @AppStorage(wrappedValue: false, "Favorites.VisitModeOn") var isVisitModeOnDefault: Bool

    @State var isGroupedByColor: Bool = true
    @AppStorage(wrappedValue: true, "Favorites.GroupByColor") var isGroupedByColorDefault: Bool

    @State var isInitialLoadCompleted: Bool = false

    @Namespace var favoritesNamespace

    var body: some View {
        NavigationStack(path: $navigator[.favorites]) {
            ZStack(alignment: .center) {
                if let favoriteCircles {
                    Group {
                        if isGroupedByColor {
                            ColorGroupedCircleGrid(
                                groups: favoriteCircles,
                                showsOverlayWhenEmpty: false,
                                namespace: favoritesNamespace
                            ) { circle in
                                if !isVisitModeOn {
                                    navigator.push(.circlesDetail(circle: circle), for: .favorites)
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
                                namespace: favoritesNamespace
                            ) { circle in
                                navigator.push(.circlesDetail(circle: circle), for: .favorites)
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
            .toolbarBackground(.automatic, for: .navigationBar)
            .toolbarBackground(.hidden, for: .tabBar)
            .overlay {
                if isVisitModeOn {
                    GradientBorder()
                        .ignoresSafeArea(edges: .horizontal)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                BarAccessory(placement: .bottom) {
                    FavoritesToolbar(
                        selectedDate: $selectedDate,
                        isVisitModeOn: $isVisitModeOn,
                        isGroupedByColor: $isGroupedByColor
                    )
                }
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
                    selectedDate = dates.first(where: {$0.id == selectedDateID})
                    isVisitModeOn = isVisitModeOnDefault
                    isGroupedByColor = isGroupedByColorDefault
                    isInitialLoadCompleted = true
                }
            }
            .onChange(of: selectedDate) { _, _ in
                if isInitialLoadCompleted {
                    selectedDateID = selectedDate?.id ?? 0
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
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .circlesDetail(let circle):
                    CircleDetailView(
                        circle: circle,
                        previousCircle: { previousCircle(for: $0) },
                        nextCircle: { nextCircle(for: $0) }
                    )
                        .automaticNavigationTransition(id: circle.id, in: favoritesNamespace)
                default: Color.clear
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
                    if let selectedDate {
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
