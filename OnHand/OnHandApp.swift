//
//  OnHandApp.swift
//  OnHand
//
//  Created by シン・ジャスティン on 2026/08/19.
//

import SwiftUI

@main
struct OnHandApp: App {

    @State var store = OnHandStore()

    var body: some Scene {
        WindowGroup {
            OnHandRootView()
                .environment(store)
                .task {
                    store.activate()
                }
        }
    }
}
