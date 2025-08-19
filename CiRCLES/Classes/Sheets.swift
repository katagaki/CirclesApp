//
//  Sheets.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/08/18.
//

import Observation
import SwiftUI

@Observable
class Sheets {

    var isPresented: Bool = false
    // Currently displayed sheet's data representation
    var current: UnifiedPath? = .circles
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

    func append(_ newPath: UnifiedPath) {
        if self.current != nil {
            self.path.append(newPath)
            self.isPresented = true
        } else {
            self.show(newPath)
        }
    }
}
