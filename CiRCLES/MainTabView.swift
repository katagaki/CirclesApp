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
            Color.clear
                .tabItem {
                    Label("Tab.Map", systemImage: "map.fill")
                }
            Color.clear
                .tabItem {
                    Label("Tab.Circles", systemImage: "square.grid.3x3.fill")
                }
            Color.clear
                .tabItem {
                    Label("Tab.Checklists", systemImage: "checklist")
                }
            Color.clear
                .tabItem {
                    Label("Tab.Profile", systemImage: "person.crop.circle.fill")
                }
            Color.clear
                .tabItem {
                    Label("Tab.More", systemImage: "ellipsis")
                }
        }
    }
}
