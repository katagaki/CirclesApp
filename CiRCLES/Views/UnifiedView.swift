//
//  UnifiedView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/08/18.
//

import Komponents
import SwiftUI

struct UnifiedView: View {

    @Environment(Events.self) var planner
    @Environment(Sheets.self) var sheets

    @State var viewPath: [UnifiedPath] = []

    let unifiedSheetTransitionId = "Unified.Sheet"
    @Namespace var namespace

    var body: some View {
        NavigationStack(path: $viewPath) {
            @Bindable var sheets = sheets
            InteractiveMap(namespace: namespace)
                .navigationBarTitleDisplayMode(.inline)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Tab.My", image: .tabIconMy) {
                            self.viewPath.append(.my)
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        UnifiedControl()
                            .foregroundStyle(.primary)
                            .glassEffect(.regular.interactive())
                            .adaptiveShadow()
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Tab.More", systemImage: "ellipsis") {
                            self.viewPath.append(.more)
                        }
                    }
                    // ToolbarItemGroup(placement: .bottomBar) { ...
                    ToolbarItem(placement: .bottomBar) {
                        HStack(spacing: 18.0) {
                            Button("Tab.Circles", systemImage: "square.grid.3x3.fill") {
                                self.sheets.show(.circles)
                            }
                            if planner.isActiveEventLatest {
                                Button("Tab.Favorites", systemImage: "star.fill") {
                                    self.sheets.show(.favorites)
                                }
                            }
                        }
                        .padding(.horizontal, 2.0)
                    }
                    .matchedTransitionSource(id: unifiedSheetTransitionId, in: namespace)
                    ToolbarSpacer(placement: .bottomBar)
//                    ToolbarSpacer(.flexible)
//                    ToolbarItemGroup(placement: .bottomBar) {
//                        // TODO: Map controls
//                    }
                }
                .sheet(isPresented: $sheets.isPresented) {
                    NavigationStack(path: $sheets.path) {
                        self.sheets.current?.view()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button(role: .close) {
                                        self.sheets.hide()
                                    }
                                }
                            }
                            .navigationDestination(for: UnifiedPath.self) { path in
                                return path.view()
                            }
                    }
                    .presentationContentInteraction(.scrolls)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationDetents([.medium, .large])
                    .navigationTransition(.zoom(sourceID: unifiedSheetTransitionId, in: namespace))
                }
                .navigationDestination(for: UnifiedPath.self) { path in
                    return path.view()
                }
                .authenticated()
        }
    }
}
