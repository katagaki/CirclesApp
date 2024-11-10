//
//  Rotation.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/17.
//

import SwiftUI

// Adapted from https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-device-rotation

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
        #if !os(visionOS)
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
        #endif
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}
