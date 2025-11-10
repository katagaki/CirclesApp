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
    
    @State var isShowingTranslationPopover: Bool = false
    
    var body: some View {
        Section {
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
        } header: {
            Text(LocalizedStringKey(title))
        }
    }
}
