//
//  MyToolbar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/08.
//

import Komponents
import SwiftUI

struct MyToolbar: ToolbarContent {
    @Environment(\.dismiss) var dismiss

    @Binding var eventTitle: String?
    @Binding var isShowingEventCoverImage: Bool

    var body: some ToolbarContent {
        if UIDevice.current.userInterfaceIdiom != .pad {
            ToolbarItem(placement: .primaryAction) {
                Button(eventTitle ?? String(localized: "ViewTitle.My"), systemImage: "photo") {
                    withAnimation(.smooth.speed(2.0)) {
                        isShowingEventCoverImage.toggle()
                    }
                }
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            if #available(iOS 26.0, *) {
                Button(role: .close) {
                    dismiss()
                }
            } else {
                CloseButton {
                    dismiss()
                }
            }
        }
    }
}
