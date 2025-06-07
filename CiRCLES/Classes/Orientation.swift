//
//  Orientation.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/01.
//

import Foundation
import SwiftUI

@Observable
class Orientation {
    private var orientation: UIDeviceOrientation

    @MainActor
    init() {
        self.orientation = UIDevice.current.orientation
    }

    @MainActor
    func update() {
        if UIDevice.current.orientation == .portrait ||
            UIDevice.current.orientation == .landscapeLeft ||
            UIDevice.current.orientation == .landscapeRight {
            self.orientation = UIDevice.current.orientation
        }
    }

    @MainActor
    func update(to orientation: UIDeviceOrientation) {
        self.orientation = orientation
    }

    @MainActor
    func isPortrait() -> Bool {
        return orientation.isPortrait || UIDevice.current.userInterfaceIdiom != .phone
    }

    @MainActor
    func isLandscape() -> Bool {
        return orientation.isLandscape && UIDevice.current.userInterfaceIdiom == .phone
    }

    @MainActor
    func isFaceUpOrDown() -> Bool {
        return orientation.isFlat
    }
}
