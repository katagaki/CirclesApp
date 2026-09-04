import Observation
import SwiftUI

enum UnifiedDisplayMode {
    case sheet
    case panel
}

enum UnifiedControlMenu {
    case date
    case hall
}

enum SidebarPosition {
    case leading
    case trailing
}

@Observable
class Unifier {

    var displayMode: UnifiedDisplayMode

    var isPresenting: Bool = false
    var sidebarPosition: SidebarPosition = .leading

    var windowSize: CGSize = .zero
    var isPanelSideDocked: Bool {
        windowSize.width > windowSize.height
    }

    @MainActor
    init() {
        self.displayMode = UIDevice.current.userInterfaceIdiom == .phone ? .sheet : .panel
    }

    // Currently displayed sheet's data representation
    var current: UnifiedPath? = .circles
    var selectedDetent: PresentationDetent = .height(360)
    var isMinimized: Bool {
        displayMode == .sheet && selectedDetent != .height(360) && selectedDetent != .large
    }
    var compactBarHeight: CGFloat = 76.0
    var compactDetent: PresentationDetent {
        .height(compactBarHeight)
    }
    var safeAreaHeight: CGFloat {
        if !isPresenting {
            return 0
        } else {
            var height: CGFloat = .zero
            if selectedDetent == .height(360) {
                height = 360.0
            } else if selectedDetent != .large {
                height = compactBarHeight
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

    // Date and hall menus, drawn as overlays so the panel stays open
    var presentedControlMenu: UnifiedControlMenu?
    var controlFrame: CGRect = .zero

    // Pending attachment from action extension
    var pendingAttachmentData: Data?

    // Alerts
    var isGoingToSignOut: Bool = false
    var isGoingToEnterOfflineMode: Bool = false
    var isGoingToExitOfflineMode: Bool = false
    var isOfflineModeTipShowing: Bool = false

    // Quick access bar search request
    var isSearchRequested: Bool = false

    // Data update trigger
    var shouldUpdateData: Bool = false

    var animatesReload: Bool = true

    @MainActor
    func show(animated: Bool = true) {
        if current == nil {
            current = .circles
        }
        // Only set isPresented in sheet mode, the iPad panel is always visible
        if displayMode == .sheet {
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
    func updateCompactBarHeight(_ newValue: CGFloat) {
        let newHeight = max(60.0, newValue.rounded())
        guard newHeight != compactBarHeight else { return }
        let previousHeight = compactBarHeight
        compactBarHeight = newHeight
        if selectedDetent == .height(previousHeight) {
            selectedDetent = .height(newHeight)
        }
    }

    @MainActor
    func collapse() {
        guard displayMode == .sheet else { return }
        selectedDetent = compactDetent
    }

    @MainActor
    func expand() {
        guard displayMode == .sheet, isMinimized else { return }
        selectedDetent = .height(360)
    }

    @MainActor
    func requestSearch() {
        if current != .circles {
            current = .circles
        }
        expand()
        isSearchRequested = true
    }

    @MainActor
    func hide() {
        // Only hide in sheet mode, the iPad panel is always visible
        if displayMode == .sheet {
            self.isPresenting = false
        }
    }

    @MainActor
    func close() {
        if displayMode == .sheet {
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
            if displayMode == .sheet {
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

    @MainActor
    func updateDisplayMode(_ newMode: UnifiedDisplayMode) {
        guard newMode != displayMode else { return }
        displayMode = newMode
        switch newMode {
        case .sheet:
            show()
        case .panel:
            isPresenting = false
            selectedDetent = .height(360)
            if current == nil {
                current = .circles
            }
        }
    }

    @MainActor
    func updateWindowSize(_ size: CGSize) {
        windowSize = size
    }
}
