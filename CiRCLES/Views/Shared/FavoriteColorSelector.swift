//
//  FavoriteColorSelector.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/04.
//

import SwiftUI

struct FavoriteColorSelector: View {

    var initialColor: WebCatalogColor?
    var initialMemo: String
    var isExistingFavorite: Bool
    var onSave: (WebCatalogColor, String) -> Void
    var onDelete: () -> Void
    
    @State private var selectedColor: WebCatalogColor?
    @State private var memo: String
    let colors: [WebCatalogColor] = WebCatalogColor.allCases
    
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
            VStack(alignment: .center, spacing: 16.0) {
                Text("Shared.SelectColor")
                    .fontWeight(.semibold)
                LazyVGrid(columns: [.init(.fixed(64.0), spacing: 8.0),
                                    .init(.fixed(64.0), spacing: 8.0),
                                    .init(.fixed(64.0), spacing: 8.0)]) {
                    ForEach(colors, id: \.self) { color in
                        Button {
                            selectedColor = color
                        } label: {
                            color.backgroundColor()
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
                VStack(alignment: .leading, spacing: 8.0) {
                    Text("Shared.Memo")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Shared.Memo.Placeholder", text: $memo, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(isExistingFavorite ? "Shared.SaveFavorite" : "Shared.RegisterFavorite") {
                    if let selectedColor {
                        onSave(selectedColor, memo)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedColor == nil)
                Button("Shared.RemoveFromFavorites", role: .destructive) {
                    onDelete()
                }
            }
            .padding()
        }
        .presentationCompactAdaptation(.popover)
    }
}
