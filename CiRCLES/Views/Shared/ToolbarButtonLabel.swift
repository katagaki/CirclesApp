//
//  ToolbarButtonLabel.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/08.
//

import SwiftUI

enum ToolbarButtonLabelImageType {
    case system(String)
    case asset(String)
}

struct ToolbarButtonLabel: View {
    let text: LocalizedStringKey
    let image: ToolbarButtonLabelImageType
    let forceLabelStyle: Bool

    var padding: CGFloat {
        if #available(iOS 26.0, *) {
            return 8.0
        } else {
            return 0.0
        }
    }

    init(
        _ text: LocalizedStringKey, image: ToolbarButtonLabelImageType,
        forceLabelStyle: Bool = false
    ) {
        self.text = text
        self.image = image
        self.forceLabelStyle = forceLabelStyle
    }

    var body: some View {
        if #available(iOS 26.0, *), !forceLabelStyle {
            switch image {
            case .system(let imageName):
                Label(text, systemImage: imageName)
            case .asset(let imageName):
                Label(text, image: imageName)
            }
        } else {
            HStack(spacing: 8.0) {
                switch image {
                case .system(let imageName):
                    Image(systemName: imageName)
                        .font(.subheadline)
                case .asset(let imageName):
                    Image(imageName)
                        .font(.subheadline)
                }
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, padding)
        }
    }
}
