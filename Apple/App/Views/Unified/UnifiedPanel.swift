import SwiftUI

struct UnifiedPanel: View {

    @Environment(Unifier.self) var unifier

    var body: some View {
        @Bindable var unifier = unifier
        NavigationStack(path: $unifier.sheetPath) {
            ZStack {
                self.unifier.view()
            }
            .safeAreaInset(edge: .top, spacing: 0.0) {
                if unifier.displayMode == .sheet && unifier.selectedDetent == .large {
                    UnifiedOfflineStatus()
                        .padding(.horizontal, 16.0)
                        .padding(.bottom, 6.0)
                }
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
            UnifiedCollapsedBar()
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
        .sheet(isPresented: Binding(
            get: { unifier.isMyComiketPresenting && unifier.presentsMyComiketFromPanel },
            set: { unifier.isMyComiketPresenting = $0 }
        )) {
            MyComiketSheet()
                .presentationDetents([.large])
        }
        .circleFinderSheet()
        .presentationBackgroundInteraction(.enabled)
        .presentationDetents([unifier.compactDetent, .height(360), .large], selection: $unifier.selectedDetent)
        .presentationContentInteraction(.scrolls)
        .interactiveDismissDisabled()
    }
}
