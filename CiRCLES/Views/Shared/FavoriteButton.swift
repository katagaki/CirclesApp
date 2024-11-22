//
//  FavoriteButton.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/01.
//

import SwiftUI

struct FavoriteButton: View {

    var color: Color?
    var isFavorited: () -> Bool
    var onSelect: () -> Void

    init(
        color: Color?,
        isFavorited: @escaping () -> Bool,
        onSelect: @escaping () -> Void
    ) {
        self.color = color
        self.isFavorited = isFavorited
        self.onSelect = onSelect
    }

    var body: some View {
        Group {
            if isFavorited() {
                Button {
                    onSelect()
                } label: {
                    HStack(alignment: .center) {
                        if let color {
                            Circle()
                                .frame(width: 16.0, height: 16.0)
                                .foregroundStyle(color)
                                .overlay {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1.5)
                                }
                        }
                        Image(systemName: "star.fill")
                            .resizable()
                            .padding(2.0)
                            .frame(width: 28.0, height: 28.0)
                            .scaledToFit()
                        Text("Shared.EditFavorites")
                            .fontWeight(.medium)
                            .padding(.vertical, 5.0)
                    }
                }
            } else {
                Button {
                    onSelect()
                } label: {
                    HStack(alignment: .center) {
                        Image(systemName: "star.fill")
                            .resizable()
                            .padding(2.0)
                            .frame(width: 28.0, height: 28.0)
                            .scaledToFit()
                        Text("Shared.AddToFavorites")
                            .fontWeight(.medium)
                            .padding(.vertical, 5.0)
                    }
                }
            }
        }
        .clipShape(.capsule(style: .continuous))
        .buttonStyle(.borderedProminent)
    }
}
