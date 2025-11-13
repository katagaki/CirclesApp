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
        self.orientation = UIDevice.current.orientation
    }

    func update(to orientation: UIDeviceOrientation) {
        self.orientation = orientation
    }

    var isPortrait: Bool {
        return orientation.isPortrait || orientation == .portraitUpsideDown
    }

    var isLandscape: Bool {
        return orientation.isLandscape && orientation != .portraitUpsideDown
    }
}
