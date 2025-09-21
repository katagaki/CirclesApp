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
    @Environment(Sheets.self) var sheets

    @State var viewPath: [UnifiedPath] = []

    @AppStorage(wrappedValue: false, "Review.IsPrompted", store: .standard) var hasReviewBeenPrompted: Bool
    @AppStorage(wrappedValue: 0, "Review.LaunchCount", store: .standard) var launchCount: Int

    let unifiedSheetTransitionId = "Unified.Sheet"
    @Namespace var namespace

    var body: some View {
        NavigationStack(path: $viewPath) {
            @Bindable var sheets = sheets
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
                        Button("Tab.More", systemImage: "ellipsis") {
                            self.viewPath.append(.more)
                        }
                    }
                    // ToolbarItemGroup(placement: .bottomBar) { ...
                    bottomToolbar()
//                    ToolbarItemGroup(placement: .bottomBar) {
//                        // TODO: Map controls
//                    }
                }
                .sheet(isPresented: $sheets.isPresented) {
                    if #available(iOS 26.0, *) {
                        bottomPanel()
                            .navigationTransition(.zoom(sourceID: unifiedSheetTransitionId, in: namespace))
                    } else {
                        bottomPanel()
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
        @Bindable var sheets = sheets
        NavigationStack(path: $sheets.path) {
            self.sheets.current?.view()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        if #available(iOS 26.0, *) {
                            Button(role: .close) {
                                self.sheets.hide()
                            }
                        } else {
                            CloseButton {
                                self.sheets.hide()
                            }
                        }
                    }
                }
                .navigationDestination(for: UnifiedPath.self) { path in
                    path.view()
                }
        }
        .presentationContentInteraction(.scrolls)
        .presentationBackgroundInteraction(.enabled)
        .presentationDetents([.medium, .large])
    }

    @ToolbarContentBuilder
    func bottomToolbar() -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: .bottomBar) {
                bottomToolbarContent()
            }
            .matchedTransitionSource(id: unifiedSheetTransitionId, in: namespace)
            ToolbarSpacer(placement: .bottomBar)
        } else {
            ToolbarItem(placement: .bottomBar) {
                bottomToolbarContent()
            }
        }
    }

    @ViewBuilder
    func bottomToolbarContent() -> some View {
        HStack(spacing: 18.0) {
            Button("Tab.Circles", systemImage: "square.grid.3x3.fill") {
                self.sheets.show(.circles)
            }
            if planner.isActiveEventLatest {
                Button("Tab.Favorites", systemImage: "star.fill") {
                    self.sheets.show(.favorites)
                }
            }
        }
        .padding(.horizontal, 2.0)
    }
}
