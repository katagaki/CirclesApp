//
//  OnHandRootView.swift
//  OnHand
//
//  Created by シン・ジャスティン on 2026/08/19.
//

import SwiftUI

struct OnHandRootView: View {

    @Environment(OnHandStore.self) var store

    var body: some View {
        NavigationStack {
            if store.payload.favorites.isEmpty {
                WaitingForPhoneView()
            } else {
                RouteView()
            }
        }
    }
}

struct WaitingForPhoneView: View {

    @Environment(OnHandStore.self) var store

    var body: some View {
        ContentUnavailableView {
            Label("OnHand.NoFavorites", systemImage: "iphone")
        } description: {
            Text("OnHand.NoFavorites.Description")
        }
    }
}
