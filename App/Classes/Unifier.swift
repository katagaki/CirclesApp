import Observation
import SwiftUI

enum SidebarPosition {
    case leading
    case trailing
}

@Observable
class Unifier {

    var isPresenting: Bool = false
    var sidebarPosition: SidebarPosition = .leading

    // Currently displayed sheet's data representation
    var current: UnifiedPath? = .circles
    var selectedDetent: PresentationDetent = .height(360)
    var isMinimized: Bool {
        selectedDetent != .height(360) && selectedDetent != .large
    }
    var safeAreaHeight: CGFloat {
        if !isPresenting {
            return 0
        } else {
            var height: CGFloat = .zero
            switch self.selectedDetent {
            case .height(100): height = 100.0
            case .height(150): height = 150.0
            case .height(360): height = 360.0
            default: height = 0.0
            }
            return max(0.0, height - 60.0) + 20.0
        }
    }

    // Bottom navigation stack's view path
    var stackPath: [UnifiedPath] = []

    // Sheet's navigation stack's view path
    var sheetPath: [UnifiedPath] = []

    // Other sheets
    var isMyComiketPresenting: Bool = false

    // Pending attachment from action extension
    var pendingAttachmentData: Data?

    // Alerts
    var isGoingToSignOut: Bool = false

    // Data update trigger
    var shouldUpdateData: Bool = false

    var animatesReload: Bool = true

    @MainActor
    func show(animated: Bool = true) {
        // Only set isPresented on phone, iPad sidebar is always visible
        if UIDevice.current.userInterfaceIdiom == .phone {
            // Don't show unified sheet while attachment search is open
            guard pendingAttachmentData == nil else { return }
            if animated {
                self.isPresenting = true
            } else {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    self.isPresenting = true
                }
            }
        }
    }

    @MainActor
    func hide() {
        // Only hide on phone, iPad sidebar is always visible
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.isPresenting = false
        }
    }

    @MainActor
    func close() {
        // Only close on phone, iPad sidebar is always visible
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.isPresenting = false
        }
        self.current = nil
        self.sheetPath = []
    }

    @MainActor
    @ViewBuilder
    func view() -> some View {
        if current != nil {
            current?.view()
                .opacity(self.isMinimized ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: selectedDetent)
        } else {
            EmptyView()
        }
    }

    @MainActor
    func append(_ newPath: UnifiedPath) {
        if self.current != nil {
            self.sheetPath.append(newPath)
            // Only set isPresented on phone, iPad sidebar is always visible
            if UIDevice.current.userInterfaceIdiom == .phone {
                self.isPresenting = true
            }
        } else {
            self.current = newPath
            self.show()
        }
    }

    func toggleSidebarPosition() {
        withAnimation(.smooth.speed(2.0)) {
            sidebarPosition = sidebarPosition == .leading ? .trailing : .leading
        }
    }
}
