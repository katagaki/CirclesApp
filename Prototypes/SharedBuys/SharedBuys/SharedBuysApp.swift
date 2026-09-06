//
//  SharedBuysApp.swift
//  SharedBuys
//

import SwiftUI

@main
struct SharedBuysApp: App {

    @State var mesh = Mesh()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(mesh)
        }
    }
}
