//
//  FavoriteColorSelector.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/04.
//

import SwiftUI

struct FavoriteColorSelector: View {

    @Binding var selectedColor: WebCatalogColor?
    let colors: [WebCatalogColor] = WebCatalogColor.allCases

    var body: some View {
        ScrollView {
            VStack {
                Text("Shared.SelectColor")
                LazyHGrid(
                    rows: [.init(.fixed(64.0), spacing: 8.0),
                           .init(.fixed(64.0), spacing: 8.0),
                           .init(.fixed(64.0), spacing: 8.0)]
                ) {
                    ForEach(colors, id: \.self) { color in
                        Button {
                            selectedColor = color
                        } label: {
                            color.swiftUIColor()
                                .aspectRatio(1.0, contentMode: .fit)
                                .clipShape(.rect(cornerRadius: 6.0))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6.0)
                                        .stroke(Color.primary.opacity(0.3))
                                }
                                .overlay {
                                    if color.rawValue == selectedColor?.rawValue {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white)
                                            .font(.title2)
                                    }
                                }
                        }
                    }
                }
            }
            .padding()
        }
        .presentationCompactAdaptation(.popover)
    }
}
