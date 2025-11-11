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

    var padding: CGFloat {
        if #available(iOS 26.0, *) {
            return 8.0
        } else {
            return 0.0
        }
    }

    init(_ text: LocalizedStringKey, imageName: String) {
        self.text = text
        self.imageName = imageName
    }

    var body: some View {
        HStack(spacing: 8.0) {
            Image(systemName: imageName)
                .font(.subheadline)
            Text(text)
                .font(.subheadline)
                .fontWeight(.bold)
                .truncationMode(.middle)
        }
        .padding(.horizontal, padding)
    }
}
