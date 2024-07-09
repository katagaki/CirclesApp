//
//  MainTabView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/18.
//

import SwiftUI
import SwiftData

struct MainTabView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) var authManager

    @State var isAuthenticating: Bool = false

    var body: some View {
        TabView {
            MapView()
                .tabItem {
                    Label("Tab.Map", systemImage: "map.fill")
                }
            ContentUnavailableView("Shared.NotImplemented", systemImage: "questionmark.square.dashed")
                .tabItem {
                    Label("Tab.Circles", systemImage: "square.grid.3x3.fill")
                }
            ContentUnavailableView("Shared.NotImplemented", systemImage: "questionmark.square.dashed")
                .tabItem {
                    Label("Tab.Checklists", systemImage: "checklist")
                }
            ContentUnavailableView("Shared.NotImplemented", systemImage: "questionmark.square.dashed")
                .tabItem {
                    Label("Tab.Profile", systemImage: "person.crop.circle.fill")
                }
            ContentUnavailableView("Shared.NotImplemented", systemImage: "questionmark.square.dashed")
                .tabItem {
                    Label("Tab.More", systemImage: "ellipsis")
                }
        }
        .sheet(isPresented: $isAuthenticating) {
            SafariView(url: authManager.authURL)
                .ignoresSafeArea()
        }
        .onAppear {
            if authManager.code == nil {
                isAuthenticating = true
            }
        }
        .onChange(of: authManager.code) { _, newValue in
            isAuthenticating = newValue == nil
        }
    }
}
