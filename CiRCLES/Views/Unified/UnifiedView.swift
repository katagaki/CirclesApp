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
            MapView()
                .navigationBarTitleDisplayMode(.inline)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar {
                    UnifiedToolbar(
                        viewPath: $viewPath,
                        isMyComiketPresenting: $isMyComiketPresenting,
                        isGoingToSignOut: $isGoingToSignOut,
                        namespace: namespace
                    )
                }
                .sheet(isPresented: $unifier.isPresented) {
                    if authenticator.isAuthenticating {
                        LoginView()
                            .environment(authenticator)
                            .interactiveDismissDisabled()
                    } else {
                        if #available(iOS 26.0, *) {
                            UnifiedPanel()
                                .navigationTransition(.zoom(sourceID: "BottomPanel", in: namespace))
                        } else {
                            UnifiedPanel()
                        }
                    }
                }
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
