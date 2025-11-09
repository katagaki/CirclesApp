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

    var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom != .phone
    }

    var isVerticalOrientation: Bool {
        orientation.isPortrait()
    }

    var sidebarWidth: CGFloat {
        360.0
    }

    var sidebarHeight: CGFloat {
        600.0
    }

    var mapLeadingPadding: CGFloat {
        guard isIPad else { return 0.0 }
        if isVerticalOrientation {
            return 0.0
        } else {
            return unifier.sidebarPosition == .leading ? (sidebarWidth + 40.0) : 0.0
        }
    }

    var mapTrailingPadding: CGFloat {
        guard isIPad else { return 0.0 }
        if isVerticalOrientation {
            return 0.0
        } else {
            return unifier.sidebarPosition == .trailing ? (sidebarWidth + 40.0) : 0.0
        }
    }

    var mapBottomPadding: CGFloat {
        guard isIPad else { return 0.0 }
        return isVerticalOrientation ? (sidebarHeight + 40.0) : 0.0
    }

    var body: some View {
        NavigationStack(path: $viewPath) {
            @Bindable var unifier = unifier
            MapView()
                .navigationBarTitleDisplayMode(.inline)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            if isIPad {
                GeometryReader { reader in
                    let alignment: Alignment = {
                        if isVerticalOrientation {
                            return .bottom
                        } else {
                            return unifier.sidebarPosition == .leading ? .leading : .trailing
                        }
                    }()
                    
                    ZStack(alignment: alignment) {
                        UnifiedPanel()
                            .frame(
                                width: isVerticalOrientation ? reader.size.width : sidebarWidth,
                                height: isVerticalOrientation ? sidebarHeight : reader.size.height * 0.85
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
                    unifier.isPresented = true
                }
            }
        }
        .onChange(of: viewPath) { _, newValue in
            if #unavailable(iOS 26.0) {
                if newValue.isEmpty {
                    unifier.isPresented = true
                }
            }
        }
        .alert("Alerts.Logout.Title", isPresented: $isGoingToSignOut) {
            Button("Shared.Cancel", role: .cancel) {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    unifier.isPresented = true
                }
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
