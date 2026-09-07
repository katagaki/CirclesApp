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
            }
            .toolbarVisibility(unifier.isMinimized ? .hidden : .visible, for: .navigationBar, .bottomBar)
            .navigationDestination(for: UnifiedPath.self) { path in
                path.view()
                    .toolbarVisibility(unifier.isMinimized ? .hidden : .visible, for: .navigationBar, .bottomBar)
            }
        }
        .overlay(alignment: .top) {
            Group {
                if let circle = unifier.minimizedCircle {
                    UnifiedCompactCircleBar(circle: circle)
                } else {
                    UnifiedQuickAccessBar()
                }
            }
            .opacity(unifier.isMinimized ? 1.0 : 0.0)
            .allowsHitTesting(unifier.isMinimized)
        }
        .animation(.easeInOut(duration: 0.2), value: unifier.isMinimized)
        .sheet(isPresented: Binding(
            get: { unifier.isSharedBuysDebugPresenting },
            set: { unifier.isSharedBuysDebugPresenting = $0 }
        )) {
            SharedBuysDebugView()
        }
        .presentationBackgroundInteraction(.enabled)
        .presentationDetents([unifier.compactDetent, .height(360), .large], selection: $unifier.selectedDetent)
        .presentationContentInteraction(.scrolls)
        .interactiveDismissDisabled()
    }
}
