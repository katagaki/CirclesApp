//
//  ListSectionWithTranslateButton.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/30.
//

import Foundation
import SwiftUI

struct ListSectionWithTranslateButton: View {
    var title: String
    var text: String
    var showContextMenu: Bool

    @State var isShowingTranslationPopover: Bool = false

    init(title: String, text: String, showContextMenu: Bool = true) {
        self.title = title
        self.text = text
        self.showContextMenu = showContextMenu
    }

    var body: some View {
        Section {
            if showContextMenu {
                #if !targetEnvironment(macCatalyst) && !os(visionOS)
                Text(text)
                    .textSelection(.enabled)
                    .contextMenu {
                        Button("Shared.Copy", systemImage: "doc.on.doc") {
                            UIPasteboard.general.string = text
                        }
                        if text.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                            Button("Shared.Translate", systemImage: "character.bubble") {
                                isShowingTranslationPopover = true
                            }
                        }
                    }
                    .translationPresentation(
                        isPresented: $isShowingTranslationPopover,
                        text: text
                    )
                #else
                Text(text)
                    .textSelection(.enabled)
                    .contextMenu {
                        Button("Shared.Copy", systemImage: "doc.on.doc") {
                            UIPasteboard.general.string = text
                        }
                    }
                #endif
            } else {
                Text(text)
                    .textSelection(.enabled)
            }
        } header: {
            Text(LocalizedStringKey(title))
        }
    }
}
