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
    private var deviceOrientation: UIDeviceOrientation

    init() {
        self.deviceOrientation = UIDevice.current.orientation
    }

    func update() {
        self.deviceOrientation = UIDevice.current.orientation
    }

    func update(to orientation: UIDeviceOrientation) {
        self.deviceOrientation = orientation
    }

    var isPortrait: Bool {
        return deviceOrientation.isPortrait || deviceOrientation == .portraitUpsideDown
    }

    var isLandscape: Bool {
        return deviceOrientation.isLandscape && deviceOrientation != .portraitUpsideDown
    }
}
