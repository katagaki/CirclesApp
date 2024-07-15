//
//  MapView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/18.
//

import SwiftUI

struct MapView: View {
    @EnvironmentObject var navigationManager: NavigationManager

    // TODO: Put this in an environment state
    @State var isSelectingEvent: Bool = false

    var body: some View {
        NavigationStack(path: $navigationManager[.map]) {
            ContentUnavailableView("Shared.NotImplemented", systemImage: "questionmark.square.dashed")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Shared.SelectEvent", systemImage: "calendar") {
                            isSelectingEvent = true
                        }
                    }
                }
                .sheet(isPresented: $isSelectingEvent) {
                    EventSelector()
                }
        }
    }
}
