//
//  ListCheckbox.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/15.
//

import SwiftUI

struct ListCheckbox: View {

    var title: LocalizedStringKey
    var description: LocalizedStringKey
    var isChecked: Bool
    var onCheckChange: (Bool) -> Void = { _ in }

    init(
        _ title: LocalizedStringKey,
        description: LocalizedStringKey,
        isChecked: Bool
    ) {
        self.title = title
        self.description = description
        self.isChecked = isChecked
    }

    init(
        _ title: LocalizedStringKey,
        description: LocalizedStringKey,
        isChecked: Bool,
        onCheckChange: @escaping (Bool) -> Void
    ) {
        self.title = title
        self.description = description
        self.isChecked = isChecked
        self.onCheckChange = onCheckChange
    }

    var body: some View {
        Button {
            onCheckChange(!isChecked)
        } label: {
            HStack {
                switch isChecked {
                case true:
                    Image(systemName: "checkmark.circle.fill")
                        .symbolRenderingMode(.multicolor)
                case false:
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
                }
                Text(title)
                Spacer()
                Text(description)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.primary)
    }
}
