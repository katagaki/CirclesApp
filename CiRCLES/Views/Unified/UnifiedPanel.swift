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
    @Environment(Orientation.self) var orientation

    var body: some View {
        @Bindable var unifier = unifier
        NavigationStack(path: $unifier.path) {
            ZStack {
                self.unifier.view()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if #available(iOS 26.0, *) {
                        viewPicker()
                    } else {
                        viewPicker()
                            .fixedSize()
                    }
                }
                if #available(iOS 26.0, *) {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Shared.ClosePanel", systemImage: "chevron.down") {
                                self.unifier.hide()
                            }
                        }
                    }
                }
                if UIDevice.current.userInterfaceIdiom != .phone && orientation.isLandscape {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(
                            "Shared.ToggleSidebarPosition",
                            systemImage: unifier.sidebarPosition == .leading ?
                            "sidebar.leading" : "sidebar.trailing"
                        ) {
                            self.unifier.toggleSidebarPosition()
                        }
                    }
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

    @ViewBuilder
    func viewPicker() -> some View {
        @Bindable var unifier = unifier
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
