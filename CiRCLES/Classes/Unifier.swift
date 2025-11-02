//
//  Unifier.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/08/18.
//

import Observation
import SwiftUI

@Observable
class Unifier {

    var isPresented: Bool = false

    // Currently displayed sheet's data representation
    var current: UnifiedPath? = .circles
    var selectedDetent: PresentationDetent = .medium
    var isMinimized: Bool {
        selectedDetent != .medium && selectedDetent != .large
    }

    // Currently displayed sheet's navigation stack's view path
    var path: [UnifiedPath] = []

    func show(_ newPath: UnifiedPath) {
        self.current = newPath
        self.path.removeAll()
        self.isPresented = true
    }

    func hide() {
        self.isPresented = false
    }

    func close() {
        self.isPresented = false
        self.current = nil
        self.path = []
    }

    @MainActor
    @ViewBuilder
    func view() -> some View {
        if current != nil {
            current?.view()
                .opacity(self.isMinimized ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: selectedDetent)
        } else {
            EmptyView()
        }
    }

    func append(_ newPath: UnifiedPath) {
        if self.current != nil {
            self.path.append(newPath)
            self.isPresented = true
        } else {
            self.show(newPath)
        }
    }
}
