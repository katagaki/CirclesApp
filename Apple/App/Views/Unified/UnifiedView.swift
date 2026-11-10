import StoreKit
import SwiftUI
import TipKit
import AXiS

struct UnifiedView: View {

    @Environment(\.requestReview) var requestReview
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(Authenticator.self) var authenticator
    @Environment(Events.self) var planner
    @Environment(Unifier.self) var unifier
    @Environment(Oasis.self) var oasis

    @Namespace var namespace

    @AppStorage(wrappedValue: false, "Review.IsPrompted", store: .standard) var hasReviewBeenPrompted: Bool
    @AppStorage(wrappedValue: 0, "Review.LaunchCount", store: .standard) var launchCount: Int

    let sidebarWidth: CGFloat = 360.0
    let sidebarHeight: CGFloat = 400.0

    var isiPad: Bool {
        UIDevice.current.userInterfaceIdiom != .phone
    }

    var displayMode: UnifiedDisplayMode {
        isiPad && horizontalSizeClass == .regular ? .panel : .sheet
    }

    var mapLeadingPadding: CGFloat {
        guard unifier.displayMode == .panel, unifier.isPanelSideDocked else { return 0.0 }
        return unifier.sidebarPosition == .leading ? (sidebarWidth + 40.0) : 0.0
    }

    var mapTrailingPadding: CGFloat {
        guard unifier.displayMode == .panel, unifier.isPanelSideDocked else { return 0.0 }
        return unifier.sidebarPosition == .trailing ? (sidebarWidth + 40.0) : 0.0
    }

    var mapBottomPadding: CGFloat {
        switch unifier.displayMode {
        case .sheet:
            return unifier.safeAreaHeight
        case .panel:
            return unifier.isPanelSideDocked ? 0.0 : (sidebarHeight + 40.0)
        }
    }

    var body: some View {
        @Bindable var unifier = unifier
        NavigationStack(path: $unifier.stackPath) {
            MapView()
                .navigationTitle("ViewTitle.Map")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(removing: .title)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all, edges: isiPad ? [] : .top) // HACK: .top breaks iPad UI
                .contentShape(.rect)
                .simultaneousGesture(TapGesture().onEnded { unifier.closeOfflineStatus() })
                .overlay(alignment: .top) {
                    UnifiedTopStatus()
                    .padding(.horizontal, 12.0)
                    .padding(.top, 8.0)
                }
                .safeAreaPadding(.leading, mapLeadingPadding)
                .safeAreaPadding(.trailing, mapTrailingPadding)
                .safeAreaPadding(.bottom, mapBottomPadding)
                .toolbar {
                    UnifiedToolbar(namespace: namespace)
                }
                .unifierPanel(namespace: namespace)
                .sheet(isPresented: Binding(
                    get: { unifier.isMyComiketPresenting && !unifier.presentsMyComiketFromPanel },
                    set: { unifier.isMyComiketPresenting = $0 }
                )) {
                    MyComiketSheet()
                        .presentationDetents([.large])
                }
                .navigationDestination(for: UnifiedPath.self) { path in
                    path.view()
                        .safeAreaPadding(.leading, mapLeadingPadding)
                        .safeAreaPadding(.trailing, mapTrailingPadding)
                        .safeAreaPadding(.bottom, mapBottomPadding)
                }
        }
        .overlay {
            switch unifier.presentedControlMenu {
            case .date: DateSelectorMenu()
            case .hall: HallMinimapMenu()
            case nil: EmptyView()
            }
        }
        .task {
            prepareTipKit()
            showReviewPromptIfLaunchedEnoughTimes()
        }
        .loginSheet()
        .dataLifecycle()
        .backupLifecycle()
        .urlSchemeHandler()
        .reachabilitySetup()
        #if DEBUG
        .debugOverlay()
        #endif
        .onChange(of: horizontalSizeClass, initial: true) { _, _ in
            unifier.updateDisplayMode(displayMode)
        }
        .background {
            Color.clear
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                } action: { newValue in
                    unifier.updateWindowSize(newValue)
                }
                .ignoresSafeArea()
        }
        .overlay {
            if unifier.displayMode == .panel {
                GeometryReader { reader in
                    let isSideDocked = unifier.isPanelSideDocked
                    let alignment: Alignment = {
                        if !isSideDocked {
                            return .bottom
                        } else {
                            return unifier.sidebarPosition == .leading ? .bottomLeading : .bottomTrailing
                        }
                    }()
                    ZStack(alignment: alignment) {
                        UnifiedPanel()
                            .frame(
                                width: isSideDocked ? sidebarWidth : reader.size.width - 40.0,
                                height: isSideDocked ? reader.size.height * 0.85 : sidebarHeight
                            )
                            .glassEffect(.regular, in: .rect(cornerRadius: 20.0))
                            .clipShape(.rect(cornerRadius: 20.0))
                            .padding(20.0)
                            .shadow(color: .black.opacity(0.1), radius: 16.0, y: 2.0)
                        Color.clear
                    }
                }
            }
        }
        .onChange(of: unifier.sheetPath) { _, newValue in
            if !newValue.isEmpty && !unifier.isPresenting {
                unifier.show()
            }
        }
        .alert("Alerts.OfflineMode.Enter.Title", isPresented: $unifier.isGoingToEnterOfflineMode) {
            Button("Shared.Cancel", role: .cancel) {
                unifier.show()
            }
            Button("More.EnterOfflineMode", action: enterOfflineMode)
        } message: {
            Text("Alerts.OfflineMode.Enter.Message")
        }
        .alert("Alerts.OfflineMode.Exit.Title", isPresented: $unifier.isGoingToExitOfflineMode) {
            Button("Shared.Cancel", role: .cancel) {
                unifier.show()
            }
            Button("More.ExitOfflineMode", action: exitOfflineMode)
        } message: {
            Text("Alerts.OfflineMode.Exit.Message")
        }
    }

    func prepareTipKit() {
        // Set by the AppStoreScreenshots UI test, so no tip covers a capture.
        if CommandLine.arguments.contains("-HidesAllTips") {
            Tips.hideAllTipsForTesting()
        }
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }

    func showReviewPromptIfLaunchedEnoughTimes() {
        launchCount += 1
        guard launchCount > 2, !hasReviewBeenPrompted else { return }
        Task {
            try? await Task.sleep(for: .seconds(8))
            guard authenticator.isReady, !authenticator.isAuthenticating, !oasis.isShowing else { return }
            requestReview()
            hasReviewBeenPrompted = true
        }
    }

    func enterOfflineMode() {
        unifier.close()
        authenticator.enterOfflineMode()
    }

    func exitOfflineMode() {
        unifier.close()
        authenticator.exitOfflineMode()
    }
}
