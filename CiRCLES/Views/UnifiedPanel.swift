//
//  UnifiedPanel.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/08.
//

import SwiftUI

struct UnifiedPanel: View {

    @Environment(Events.self) var planner
    @Environment(Unifier.self) var unifier

    var body: some View {
        @Bindable var unifier = unifier
        NavigationStack(path: $unifier.path) {
            ZStack {
                self.unifier.view()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker(selection: $unifier.current) {
                        Text("ViewTitle.Circles")
                            .tag(UnifiedPath.circles)
                        if planner.isActiveEventLatest {
                            Text("ViewTitle.Favorites")
                                .tag(UnifiedPath.favorites)
                        }
                    } label: { }
                        .id("Unifier.Picker")
                        .pickerStyle(.segmented)
                }
            }
            .navigationDestination(for: UnifiedPath.self) { path in
                path.view()
            }
        }
        .presentationContentInteraction(.scrolls)
        .presentationBackgroundInteraction(.enabled)
        .presentationDetentsForUnifiedView($unifier.selectedDetent)
        .interactiveDismissDisabled()
    }
}
