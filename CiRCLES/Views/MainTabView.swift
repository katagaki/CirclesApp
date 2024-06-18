//
//  ContentView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/18.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext

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
        .sheet(isPresented: .constant(true)) {
            LoginView()
        }
    }
}
