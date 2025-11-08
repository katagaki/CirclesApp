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
    var selectedDetent: PresentationDetent = .height(360)
    var isMinimized: Bool {
        selectedDetent != .height(360) && selectedDetent != .large
    }
    var safeAreaHeight: CGFloat {
        if !isPresented {
            return 0
        } else {
            var height: CGFloat = .zero
            switch self.selectedDetent {
            case .height(120):
                height = 120.0
            case .height(150):
                height = 150.0
            case .height(360):
                height = 360.0
            default:
                height = 0.0
            }
            if #available(iOS 26.0, *) {
                return max(0.0, height - 60.0)
            } else {
                return height
            }
        }
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
