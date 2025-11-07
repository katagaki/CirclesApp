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

    @State var viewPath: [UnifiedPath] = []

    @State var isMyComiketPresenting: Bool = false
    @State var isGoingToSignOut: Bool = false

    @Namespace var namespace

    @AppStorage(wrappedValue: false, "Review.IsPrompted", store: .standard) var hasReviewBeenPrompted: Bool
    @AppStorage(wrappedValue: 0, "Review.LaunchCount", store: .standard) var launchCount: Int

    var body: some View {
        NavigationStack(path: $viewPath) {
            @Bindable var unifier = unifier
            Map()
                .navigationBarTitleDisplayMode(.inline)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Tab.My", image: .tabIconMy) {
                            unifier.isPresented = false
                            isMyComiketPresenting = true
                        }
                        .aspectRatio(1.0, contentMode: .fit)
                        .matchedTransitionSource(id: "My.View", in: namespace)
                    }
                    ToolbarItem(placement: .principal) {
                        UnifiedControl()
                            .foregroundStyle(.primary)
                            .glassEffectInteractiveIfSupported()
                            .adaptiveShadow()
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        MoreMenu(
                            viewPath: $viewPath,
                            isGoingToSignOut: $isGoingToSignOut
                        )
                            .popoverTip(GenreOverlayTip())
                    }
                }
                .sheet(isPresented: $unifier.isPresented) {
                    if authenticator.isAuthenticating {
                        LoginView()
                            .environment(authenticator)
                            .interactiveDismissDisabled()
                    } else {
                        bottomPanel()
                    }
                }
                .fullScreenCover(isPresented: $isMyComiketPresenting) {
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
                .navigationDestination(for: UnifiedPath.self) { path in
                    path.view()
                }
                .task {
                    prepareTipKit()
                    showReviewPromptIfLaunchedEnoughTimes()
                }
                .authenticated()
                #if DEBUG
                .debugOverlay()
                #endif
        }
        .alert("Alerts.Logout.Title", isPresented: $isGoingToSignOut) {
            Button("Shared.Cancel", role: .cancel) {
                unifier.isPresented = true
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

    @ViewBuilder
    func bottomPanel() -> some View {
        @Bindable var unifier = unifier
        NavigationStack(path: $unifier.path) {
            ZStack {
                self.unifier.view()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
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
    func bottomToolbarContent() -> some View {
        HStack(spacing: 18.0) {
            Button("Tab.Circles", systemImage: "square.grid.3x3.fill") {
                self.unifier.show(.circles)
            }
            if planner.isActiveEventLatest {
                Button("Tab.Favorites", systemImage: "star.fill") {
                    self.unifier.show(.favorites)
                }
            }
        }
        .padding(.horizontal, 2.0)
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
                unifier.close()
                authenticator.resetAuthentication()
            }
        }
    }
}
