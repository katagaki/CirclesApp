//
//  Orientation.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/01.
//

import Foundation
import SwiftUI

@Observable
@MainActor
class Orientation {
    private var orientation: UIDeviceOrientation

    init() {
        self.orientation = UIDevice.current.orientation
    }

    func update() {
        if UIDevice.current.orientation == .portrait ||
            UIDevice.current.orientation == .landscapeLeft ||
            UIDevice.current.orientation == .landscapeRight {
            self.orientation = UIDevice.current.orientation
        }
    }

    func update(to orientation: UIDeviceOrientation) {
        self.orientation = orientation
    }

    func isPortrait() -> Bool {
        return orientation.isPortrait || UIDevice.current.orientation == .portraitUpsideDown
    }

    func isLandscape() -> Bool {
        return orientation.isLandscape && UIDevice.current.orientation != .portraitUpsideDown
    }
}
