//
//  UnifiedView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/08/18.
//

import Komponents
import StoreKit
import SwiftUI
import TipKit

struct UnifiedView: View {

    @Environment(\.requestReview) var requestReview
    @Environment(Authenticator.self) var authenticator
    @Environment(Database.self) var database
    @Environment(ImageCache.self) var imageCache
    @Environment(Events.self) var planner
    @Environment(Unifier.self) var unifier
    @Environment(Orientation.self) var orientation

    @State var viewPath: [UnifiedPath] = []

    @State var isMyComiketPresenting: Bool = false
    @State var isGoingToSignOut: Bool = false

    @Namespace var namespace

    @AppStorage(wrappedValue: false, "Review.IsPrompted", store: .standard) var hasReviewBeenPrompted: Bool
    @AppStorage(wrappedValue: 0, "Review.LaunchCount", store: .standard) var launchCount: Int

    var isiPad: Bool {
        UIDevice.current.userInterfaceIdiom != .phone
    }

    let sidebarWidth: CGFloat = 360.0
    let sidebarHeight: CGFloat = 400.0

    var mapLeadingPadding: CGFloat {
        guard isiPad else { return 0.0 }
        if orientation.isPortrait {
            return 0.0
        } else {
            return unifier.sidebarPosition == .leading ? (sidebarWidth + 40.0) : 0.0
        }
    }

    var mapTrailingPadding: CGFloat {
        guard isiPad else { return 0.0 }
        if orientation.isPortrait {
            return 0.0
        } else {
            return unifier.sidebarPosition == .trailing ? (sidebarWidth + 40.0) : 0.0
        }
    }

    var mapBottomPadding: CGFloat {
        guard isiPad else { return unifier.safeAreaHeight }
        return orientation.isPortrait ? (sidebarHeight + 40.0) : 0.0
    }

    var body: some View {
        NavigationStack(path: $viewPath) {
            @Bindable var unifier = unifier
            MapView()
                .navigationTitle("ViewTitle.Map")
                .navigationBarTitleDisplayMode(.inline)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all, edges: .top)
                .safeAreaPadding(.leading, mapLeadingPadding)
                .safeAreaPadding(.trailing, mapTrailingPadding)
                .safeAreaPadding(.bottom, mapBottomPadding)
                .toolbar {
                    UnifiedToolbar(
                        viewPath: $viewPath,
                        isMyComiketPresenting: $isMyComiketPresenting,
                        isGoingToSignOut: $isGoingToSignOut,
                        namespace: namespace
                    )
                }
                .adaptiveNavigationBar()
                .unifierSheets(namespace: namespace)
                .sheet(isPresented: $isMyComiketPresenting) {
                    Group {
                        if #available(iOS 26.0, *) {
                            NavigationStack {
                                MyView()
                            }
                            .navigationTransition(.zoom(sourceID: "My.View", in: namespace))
                        } else {
                            NavigationStack {
                                MyView()
                            }
                        }
                    }
                    .presentationDetents([.large])
                }
                .navigationDestination(for: UnifiedPath.self) { path in
                    path.view()
                        .safeAreaPadding(.leading, mapLeadingPadding)
                        .safeAreaPadding(.trailing, mapTrailingPadding)
                        .safeAreaPadding(.bottom, mapBottomPadding)
                }
        }
        .task {
            prepareTipKit()
            showReviewPromptIfLaunchedEnoughTimes()
        }
        .authenticated()
        #if DEBUG
        .debugOverlay()
        #endif
        .overlay {
            if isiPad {
                GeometryReader { reader in
                    let alignment: Alignment = {
                        if orientation.isPortrait {
                            return .bottom
                        } else {
                            return unifier.sidebarPosition == .leading ? .bottomLeading : .bottomTrailing
                        }
                    }()
                    ZStack(alignment: alignment) {
                        UnifiedPanel()
                            .frame(
                                width: orientation.isPortrait ? reader.size.width - 40.0 : sidebarWidth,
                                height: orientation.isPortrait ? sidebarHeight : reader.size.height * 0.85
                            )
                            .adaptiveGlass(.regular, cornerRadius: 20.0)
                            .clipShape(.rect(cornerRadius: 20.0))
                            .padding(20.0)
                            .shadow(color: .black.opacity(0.1), radius: 16.0, y: 2.0)
                        Color.clear
                    }
                }
            }
        }
        .onChange(of: isMyComiketPresenting) { _, newValue in
            if #unavailable(iOS 26.0) {
                if !newValue {
                    unifier.show()
                }
            }
        }
        .onChange(of: viewPath) { _, newValue in
            if #unavailable(iOS 26.0) {
                if newValue.isEmpty {
                    unifier.show()
                }
            }
        }
        .alert("Alerts.Logout.Title", isPresented: $isGoingToSignOut) {
            Button("Shared.Cancel", role: .cancel) {
                unifier.show()
            }
            Button("Shared.Logout", role: .destructive, action: logout)
        } message: {
            Text("Alerts.Logout.Message")
        }
    }

    func prepareTipKit() {
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }

    func showReviewPromptIfLaunchedEnoughTimes() {
        launchCount += 1
        if launchCount > 2 && !hasReviewBeenPrompted {
            requestReview()
            hasReviewBeenPrompted = true
        }
    }

    func logout() {
        database.delete()
        imageCache.clear()
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
        Task.detached {
            let actor = DataConverter(modelContainer: sharedModelContainer)
            await actor.deleteAll()
            await MainActor.run {
                imageCache.clear()
                database.reset()
                unifier.close()
                authenticator.resetAuthentication()
            }
        }
    }
}
