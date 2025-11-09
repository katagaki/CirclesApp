//
//  FavoritePopover.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/04.
//

import SwiftUI

struct FavoritePopover: View {

    var initialColor: WebCatalogColor?
    var initialMemo: String
    var isExistingFavorite: Bool
    var onSave: (WebCatalogColor, String) -> Void
    var onDelete: () -> Void

    @State private var selectedColor: WebCatalogColor?
    @State private var memo: String
    let colors: [WebCatalogColor] = WebCatalogColor.allCases

    var cornerRadius: CGFloat {
        if #available(iOS 26.0, *) {
            return 12.0
        } else {
            return 8.0
        }
    }

    init(
        initialColor: WebCatalogColor?,
        initialMemo: String,
        isExistingFavorite: Bool,
        onSave: @escaping (WebCatalogColor, String) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.initialColor = initialColor
        self.initialMemo = initialMemo
        self.isExistingFavorite = isExistingFavorite
        self.onSave = onSave
        self.onDelete = onDelete
        self._selectedColor = State(initialValue: initialColor)
        self._memo = State(initialValue: initialMemo)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16.0) {
                VStack(alignment: .leading, spacing: 8.0) {
                    Text("Shared.SelectColor")
                        .fontWeight(.semibold)
                    LazyVGrid(
                        columns: [.init(.fixed(64.0), spacing: 8.0),
                                  .init(.fixed(64.0), spacing: 8.0),
                                  .init(.fixed(64.0), spacing: 8.0)]
                    ) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                color.backgroundColor()
                                    .aspectRatio(1.0, contentMode: .fit)
                                    .clipShape(.rect(cornerRadius: cornerRadius))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: cornerRadius)
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
                    .frame(height: ((64.0 * 3) + (8.0 * 2)))
                }
                VStack(alignment: .leading, spacing: 8.0) {
                    Text("Shared.Memo.Placeholder")
                        .fontWeight(.semibold)
                    TextEditor(text: $memo)
                        .clipShape(.rect(cornerRadius: cornerRadius))
                        .frame(height: 64.0)
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color.primary.opacity(0.3))
                        }
                }
                VStack(alignment: .leading, spacing: 8.0) {
                    Button {
                        if let selectedColor {
                            onSave(selectedColor, memo)
                        }
                    } label: {
                        Label(
                            isExistingFavorite ? "Shared.SaveFavorite" : "Shared.AddToFavorites",
                            systemImage: "plus"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(selectedColor == nil)
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label(
                            "Shared.RemoveFromFavorites",
                            systemImage: "minus.circle"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(initialColor == nil)
                }
                .buttonStyleGlassProminentIfSupported()
            }
            .padding()
        }
        .presentationCompactAdaptation(.popover)
    }
}
