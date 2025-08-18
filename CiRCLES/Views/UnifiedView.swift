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

    @Namespace var namespace

    var body: some View {
        NavigationStack(path: $viewPath) {
            @Bindable var sheets = sheets
            InteractiveMap(namespace: namespace)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    ZStack(alignment: .top) {
                        UnifiedControl()
                            .foregroundStyle(.primary)
                            .glassEffect(.regular.interactive())
                            .padding()
                        Color.clear
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Tab.My", image: .tabIconMy) {
                            self.viewPath.append(.my)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Tab.More", systemImage: "ellipsis") {
                            self.viewPath.append(.more)
                        }
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button("Tab.Circles", systemImage: "square.grid.3x3.fill") {
                            self.sheets.show(.circles)
                        }
                        if planner.isActiveEventLatest {
                            Button("Tab.Favorites", systemImage: "star.fill") {
                                self.sheets.show(.favorites)
                            }
                        }
                    }
                    .matchedTransitionSource(id: "Unified.Sheet", in: namespace)
                    ToolbarSpacer(placement: .bottomBar)
//                    ToolbarSpacer(.flexible)
//                    ToolbarItemGroup(placement: .bottomBar) {
//                        // TODO: Map controls
//                    }
                }
                .sheet(isPresented: $sheets.isPresented) {
                    NavigationStack(path: $sheets.path) {
                        self.sheets.current?.view()
                            .navigationDestination(for: UnifiedPath.self) { path in
                                return path.view()
                            }
                    }
                    .presentationContentInteraction(.scrolls)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationDetents([.medium, .large])
                    .navigationTransition(.zoom(sourceID: "Unified.Sheet", in: namespace))
                }
                .navigationDestination(for: UnifiedPath.self) { path in
                    return path.view()
                }
                .authenticated()
        }
    }
}
