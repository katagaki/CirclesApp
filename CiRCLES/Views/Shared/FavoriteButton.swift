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
    var addToFavorites: () -> Void
    var deleteFromFavorites: () -> Void

    init(
        color: Color?,
        isFavorited: @escaping () -> Bool,
        onAdd addToFavorites: @escaping () -> Void,
        onDelete deleteFromFavorites: @escaping () -> Void
    ) {
        self.color = color
        self.isFavorited = isFavorited
        self.addToFavorites = addToFavorites
        self.deleteFromFavorites = deleteFromFavorites
    }

    var body: some View {
        Group {
            if isFavorited() {
                Button {
                    deleteFromFavorites()
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
                        Image(systemName: "star.slash.fill")
                            .resizable()
                            .padding(2.0)
                            .frame(width: 28.0, height: 28.0)
                            .scaledToFit()
                        Text("Shared.RemoveFromFavorites")
                    }
                }
            } else {
                Button {
                    addToFavorites()
                } label: {
                    Image(systemName: "star.fill")
                        .resizable()
                        .padding(2.0)
                        .frame(width: 28.0, height: 28.0)
                        .scaledToFit()
                    Text("Shared.AddToFavorites")
                }
            }
        }
        .clipShape(.capsule(style: .continuous))
        .buttonStyle(.borderedProminent)
    }
}
