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

    @AppStorage(wrappedValue: true, "Favorites.GroupByColor") var isGroupedByColorDefault: Bool
    @AppStorage(wrappedValue: .grid, "Favorites.DisplayMode") var displayModeDefault: CircleDisplayMode
    @AppStorage(wrappedValue: ListDisplayMode.regular, "Favorites.ListDisplayMode") var listDisplayModeDefault: ListDisplayMode

    @State var displayModeState: CircleDisplayMode = .grid
    @State var listDisplayModeState: ListDisplayMode = .regular

    @AppStorage(wrappedValue: true, "Customization.DoubleTapToVisit") var isDoubleTapToVisitEnabled: Bool

    @Namespace var namespace

    var body: some View {
        @Bindable var favorites = favorites

        let doubleTapAction: ((ComiketCircle) -> Void)? = isDoubleTapToVisitEnabled ? { circle in
            let circleID = circle.id
            let eventNumber = planner.activeEventNumber
            Task.detached {
                let actor = VisitActor(modelContainer: sharedModelContainer)
                await actor.toggleVisit(circleID: circleID, eventNumber: eventNumber)
            }
        } : nil

        ZStack(alignment: .center) {
            if let favoriteCircles = favorites.circles {
                Group {
                    if favorites.isGroupedByColor {
                        if displayModeState == .list {
                            ColorGroupedCircleList(
                                groups: favoriteCircles,
                                showsOverlayWhenEmpty: false,
                                displayMode: listDisplayModeState,
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
                        } else {
                            ColorGroupedCircleGrid(
                                groups: favoriteCircles,
                                showsOverlayWhenEmpty: false,
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
                        }
                    } else {
                        if displayModeState == .list {
                            CircleList(
                                circles: favoriteCircles.values.flatMap({ $0 }).sorted(by: { $0.id < $1.id }),
                                showsOverlayWhenEmpty: false,
                                displayMode: listDisplayModeState,
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
                        } else {
                            CircleGrid(
                                circles: favoriteCircles.values.flatMap({ $0 }).sorted(by: { $0.id < $1.id }),
                                showsOverlayWhenEmpty: false,
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
        .toolbar {
            FavoritesToolbar(displayMode: $displayModeState, listDisplayMode: $listDisplayModeState)
        }
        .refreshable {
            await reloadFavorites()
            await prepareCircles(using: favorites.items ?? [])
        }
        .onAppear {
            let dateSelectionID = "D\(selections.date?.id ?? -1)"
            if favorites.invalidationID != dateSelectionID {
                if let favoriteItems = favorites.items {
                    Task { await prepareCircles(using: favoriteItems) }
                }
                favorites.invalidationID = dateSelectionID
            }

            displayModeState = displayModeDefault
            listDisplayModeState = listDisplayModeDefault
        }
        .onChange(of: displayModeState) {
            displayModeDefault = displayModeState
        }
        .onChange(of: displayModeDefault) {
             displayModeState = displayModeDefault
        }
        .onChange(of: listDisplayModeState) {
            listDisplayModeDefault = listDisplayModeState
        }
        .onChange(of: listDisplayModeDefault) {
            listDisplayModeState = listDisplayModeDefault
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
        let favoriteCircleIdentifiers = await Favorites.mapped(using: favoriteItems)
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
                self.favorites.circles = favoriteCircles
            }
        }
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
}
