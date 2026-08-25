//
//  FavoritesView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/04.
//

import SwiftData
import SwiftUI
import RADiUS
import AXiS

struct FavoritesView: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites
    @Environment(\.favoritesFilters) var filters
    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(UserSelections.self) var selections
    @Environment(Unifier.self) var unifier

    @AppStorage(wrappedValue: true, "Favorites.GroupByColor") var isGroupedByColorDefault: Bool
    @AppStorage(wrappedValue: .grid, "Favorites.DisplayMode") var displayMode: CircleDisplayMode
    @AppStorage(wrappedValue: ListDisplayMode.regular, "Favorites.ListDisplayMode") var listDisplayMode: ListDisplayMode
    @AppStorage(wrappedValue: GridDisplayMode.medium, "Favorites.GridDisplayMode") var gridDisplayMode: GridDisplayMode

    @State var displayModeState: CircleDisplayMode = .grid
    @State var listDisplayModeState: ListDisplayMode = .regular
    @State var gridDisplayModeState: GridDisplayMode = .medium

    @State var gridID = UUID()

    @AppStorage(wrappedValue: true, "Customization.DoubleTapToVisit") var isDoubleTapToVisitEnabled: Bool

    @Namespace var namespace

    var body: some View {
        ZStack(alignment: .center) {
            if let favoriteCircles = favorites.circles, !isLoadingInitialContent {
                FavoritesCircleCollection(
                    groups: favoriteCircles,
                    displayMode: displayModeState,
                    listDisplayMode: listDisplayModeState,
                    gridDisplayMode: gridDisplayModeState,
                    namespace: namespace,
                    onSelect: { circle in
                        unifier.append(.namespacedCircleDetail(
                            circle: circle,
                            previousCircle: { previousCircle(for: $0) },
                            nextCircle: { nextCircle(for: $0) },
                            namespace: namespace
                        ))
                    },
                    onDoubleTap: doubleTapAction
                )
                .id(gridID)
            } else {
                ProgressView("Favorites.Loading")
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("ViewTitle.Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            FavoritesToolbar(
                displayMode: $displayModeState,
                listDisplayMode: $listDisplayModeState,
                gridDisplayMode: $gridDisplayModeState
            )
        }
        .task {
            if favorites.items == nil {
                await favorites.loadFromCache()
            }
            if !authenticator.isOfflineModeActive {
                await favorites.refresh(authToken: authenticator.token)
            }
        }
        .onAppear {
            let dateSelectionID = "D\(selections.date?.id ?? -1)"
            if favorites.invalidationID != dateSelectionID {
                if let favoriteItems = favorites.items {
                    Task { await prepareCircles(using: favoriteItems) }
                }
                favorites.invalidationID = dateSelectionID
            }

            displayModeState = displayMode
            listDisplayModeState = listDisplayMode
            gridDisplayModeState = gridDisplayMode
        }
        .onChange(of: displayModeState) {
            displayMode = displayModeState
        }
        .onChange(of: listDisplayModeState) {
            listDisplayMode = listDisplayModeState
        }
        .onChange(of: gridDisplayModeState) {
            gridDisplayMode = gridDisplayModeState
        }
        .onChange(of: selections.date) {
            if let favoriteItems = favorites.items {
                Task { await prepareCircles(using: favoriteItems) }
            }
        }

        .onChange(of: favorites.isGroupedByColor) {
            isGroupedByColorDefault = favorites.isGroupedByColor
        }
        .onChange(of: favorites.items) {
            if let favoriteItems = favorites.items {
                Task { await prepareCircles(using: favoriteItems) }
            }
        }
    }

    var isLoadingInitialContent: Bool {
        favorites.isRefreshing && (favorites.circles?.allSatisfy({ $0.value.isEmpty }) ?? true)
    }

    func prepareCircles(using favoriteItems: [UserFavorites.Response.FavoriteItem]) async {
        let favoriteCircleIdentifiers = await Favorites.mapped(using: favoriteItems, database: database)
        let mapIDsByBlockID = await mapIDsByBlockID()

        await MainActor.run {
            var favoriteCircles: [String: [ComiketCircle]] = [:]
            var hasUncoloredFavorites: Bool = false

            for colorKey in favoriteCircleIdentifiers.keys.sorted() {
                if let circleIdentifiers = favoriteCircleIdentifiers[colorKey] {
                    var circles = database.circles(circleIdentifiers)
                    circles.sort(by: {$0.id < $1.id})
                    if let selectedDate = selections.date {
                        circles = circles.filter({ $0.day == selectedDate.id })
                    }
                    if colorKey == WebCatalogColor.uncolored.rawValue && !circles.isEmpty {
                        hasUncoloredFavorites = true
                    }
                    favoriteCircles[String(colorKey)] = circles
                }
            }

            self.filters.mapIDsByBlockID = mapIDsByBlockID
            self.filters.hasUncoloredFavorites = hasUncoloredFavorites
            withAnimation(.smooth.speed(2.0)) {
                self.favorites.circles = favoriteCircles
            }
        }
    }

    func mapIDsByBlockID() async -> [Int: Int] {
        if !filters.mapIDsByBlockID.isEmpty {
            return filters.mapIDsByBlockID
        }
        let actor = DataFetcher(database: await database.newReadOnlyTextConnection())
        return await actor.mapIDsByBlockID()
    }

    func previousCircle(for circle: ComiketCircle) -> ComiketCircle? {
        if let favoriteCircles = favorites.circles {
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
        if let favoriteCircles = favorites.circles {
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

    var doubleTapAction: ((ComiketCircle) -> Void)? {
        if isDoubleTapToVisitEnabled {
            return { circle in
                toggleVisitState(circle: circle)
            }
        }
        return nil
    }

    func toggleVisitState(circle: ComiketCircle) {
        let circleID = circle.id
        let eventNumber = planner.activeEventNumber
        Task.detached {
            let actor = VisitActor(modelContainer: sharedModelContainer)
            await actor.toggleVisit(circleID: circleID, eventNumber: eventNumber)
        }
    }
}
