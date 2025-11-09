//
//  Unifier.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/08/18.
//

import Observation
import SwiftUI

enum SidebarPosition {
    case leading
    case trailing
}

@Observable
class Unifier {

    var isPresented: Bool = false
    var sidebarPosition: SidebarPosition = .leading

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
            case .height(100):
                height = 100.0
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

    func show() {
        // Only set isPresented on phone, iPad sidebar is always visible
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.isPresented = true
        }
    }

    func hide() {
        // Only hide on phone, iPad sidebar is always visible
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.isPresented = false
        }
    }

    func close() {
        // Only close on phone, iPad sidebar is always visible
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.isPresented = false
        }
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
            // Only set isPresented on phone, iPad sidebar is always visible
            if UIDevice.current.userInterfaceIdiom == .phone {
                self.isPresented = true
            }
        } else {
            self.current = newPath
            self.show()
        }
    }

    func toggleSidebarPosition() {
        withAnimation(.smooth(duration: 0.5)) {
            sidebarPosition = sidebarPosition == .leading ? .trailing : .leading
        }
    }
}
