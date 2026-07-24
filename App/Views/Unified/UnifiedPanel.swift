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
                        Button("Shared.ClosePanel", systemImage: "chevron.down") {
                            self.unifier.hide()
                        }
                    }
                }
            }
            .navigationDestination(for: UnifiedPath.self) { path in
                path.view()
            }
        }
        .presentationBackgroundInteraction(.enabled)
        .presentationDetents([.height(150), .height(360), .large], selection: $unifier.selectedDetent)
        .presentationContentInteraction(.scrolls)
        .interactiveDismissDisabled()
    }
}
