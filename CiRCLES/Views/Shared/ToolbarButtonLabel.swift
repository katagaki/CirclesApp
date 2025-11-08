//
//  ToolbarButtonLabel.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/08.
//

import SwiftUI

struct ToolbarButtonLabel: View {
    let text: LocalizedStringKey
    let imageName: String

    init(_ text: LocalizedStringKey, imageName: String) {
        self.text = text
        self.imageName = imageName
    }

    var body: some View {
        HStack(spacing: 8.0) {
            Image(systemName: imageName)
            Text(text)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 8.0)
    }
}

