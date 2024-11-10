//
//  TranslateButton.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/02.
//

import SwiftUI

struct TranslateButton: View {

    var textToTranslate: String

    @State var isShowingTranslationPopover: Bool = false

    init(translating textToTranslate: String) {
        self.textToTranslate = textToTranslate
    }

    var body: some View {
        #if !targetEnvironment(macCatalyst) && !os(visionOS)
        Button("Shared.Translate", systemImage: "character.bubble") {
            isShowingTranslationPopover = true
        }
        .textCase(nil)
        .foregroundStyle(.teal)
        .translationPresentation(
            isPresented: $isShowingTranslationPopover,
            text: textToTranslate
        )
        #else
        Color.clear
        #endif
    }
}
