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
    @Environment(Events.self) var planner
    @Environment(Unifier.self) var unifier

    @State var viewPath: [UnifiedPath] = []

    @AppStorage(wrappedValue: false, "Review.IsPrompted", store: .standard) var hasReviewBeenPrompted: Bool
    @AppStorage(wrappedValue: 0, "Review.LaunchCount", store: .standard) var launchCount: Int

    @Namespace var namespace

    var body: some View {
        NavigationStack(path: $viewPath) {
            @Bindable var unifier = unifier
            InteractiveMap(namespace: namespace)
                .navigationBarTitleDisplayMode(.inline)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Tab.My", image: .tabIconMy) {
                            self.viewPath.append(.my)
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        UnifiedControl()
                            .foregroundStyle(.primary)
                            .glassEffectInteractiveIfSupported()
                            .adaptiveShadow()
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        MoreMenu(viewPath: $viewPath)
                    }
                }
                .sheet(isPresented: $unifier.isPresented) {
                    bottomPanel()
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
            self.unifier.view()
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Picker(selection: $unifier.current) {
                            Text("ViewTitle.Circles")
                                .tag(UnifiedPath.circles)
                            Text("ViewTitle.Favorites")
                                .tag(UnifiedPath.favorites)
                        } label: { }
                        .pickerStyle(.segmented)
                    }
                }
                .navigationDestination(for: UnifiedPath.self) { path in
                    path.view()
                }
        }
        .presentationContentInteraction(.scrolls)
        .presentationBackgroundInteraction(.enabled)
        .presentationDetents([.height(72.0), .medium, .large], selection: $unifier.selectedDetent)
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
}
