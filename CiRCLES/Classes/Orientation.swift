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
        if UIDevice.current.orientation.isPortrait {
            self.orientation = .portrait
        } else {
            self.orientation = UIDevice.current.orientation
        }
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

    func isPortrait() -> Bool {
        return orientation == .portrait
    }

    func isLandscape() -> Bool {
        return orientation == .landscapeLeft || orientation == .landscapeRight
    }

    @MainActor
    func isOniPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}
