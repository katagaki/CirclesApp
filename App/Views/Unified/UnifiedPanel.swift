import SwiftUI

struct UnifiedPanel: View {

    @Environment(Unifier.self) var unifier

    var body: some View {
        @Bindable var unifier = unifier
        NavigationStack(path: $unifier.sheetPath) {
            ZStack {
                self.unifier.view()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    UnifiedViewPicker()
                }
                if unifier.displayMode == .sheet {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Shared.CollapsePanel", systemImage: "chevron.down") {
                            self.unifier.collapse()
                        }
                    }
                }
            }
            .toolbarVisibility(unifier.isMinimized ? .hidden : .visible, for: .navigationBar, .bottomBar)
            .navigationDestination(for: UnifiedPath.self) { path in
                path.view()
                    .toolbarVisibility(unifier.isMinimized ? .hidden : .visible, for: .navigationBar, .bottomBar)
            }
        }
        .overlay(alignment: .top) {
            UnifiedQuickAccessBar()
                .opacity(unifier.isMinimized ? 1.0 : 0.0)
                .allowsHitTesting(unifier.isMinimized)
        }
        .animation(.easeInOut(duration: 0.2), value: unifier.isMinimized)
        .presentationBackgroundInteraction(.enabled)
        .presentationDetents([unifier.compactDetent, .height(360), .large], selection: $unifier.selectedDetent)
        .presentationContentInteraction(.scrolls)
        .interactiveDismissDisabled()
    }
}
