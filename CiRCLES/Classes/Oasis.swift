//
//  Oasis.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/09.
//

import Foundation
import SwiftUI

@Observable
class Oasis {

    var isModal: Bool = true
    var isProgressDeterminate: Bool = false

    var isShowing: Bool = false
    var headerText: String?
    var bodyText: String?
    var progress: Double?
    var showOfflineOption: Bool = false
    var loadStartTime: Date?

    @MainActor
    func setModality(_ isModal: Bool) async {
        withAnimation(.smooth.speed(2.0)) {
            self.isModal = isModal
        }
        try? await Task.sleep(nanoseconds: 20000000)
    }

    @MainActor
    func setHeaderText(_ headerText: String?) async {
        self.headerText = headerText
        try? await Task.sleep(nanoseconds: 20000000)
    }

    @MainActor
    func setBodyText(_ bodyText: String) async {
        self.bodyText = bodyText
        try? await Task.sleep(nanoseconds: 20000000)
    }

    @MainActor
    func setProgress(_ progress: Double?) async {
        self.progress = progress
    }

    func open(completion: (() -> Void)? = nil) {
        self.headerText = nil
        self.bodyText = nil
        self.loadStartTime = Date()
        self.showOfflineOption = false
        withAnimation(.smooth.speed(2.0)) {
            isShowing = true
        } completion: {
            if let completion {
                completion()
            }
        }
    }

    func close() {
        withAnimation(.smooth.speed(2.0)) {
            isShowing = false
        } completion: {
            self.headerText = nil
            self.bodyText = nil
            self.isModal = true
            self.showOfflineOption = false
            self.loadStartTime = nil
        }
    }
    
    @MainActor
    func checkAndShowOfflineOption() {
        if let loadStartTime = loadStartTime,
           Date().timeIntervalSince(loadStartTime) >= 2.0,
           !showOfflineOption {
            withAnimation(.smooth) {
                showOfflineOption = true
            }
        }
    }
}
