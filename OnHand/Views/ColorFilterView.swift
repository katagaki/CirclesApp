//
//  ColorFilterView.swift
//  OnHand
//
//  Created by シン・ジャスティン on 2026/08/25.
//

import SwiftUI

struct ColorFilterView: View {

    @Environment(OnHandStore.self) var store
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6.0), count: 3),
                spacing: 6.0
            ) {
                ForEach(store.availableColors, id: \.rawValue) { color in
                    Button {
                        store.colorFilter = color.rawValue
                        dismiss()
                    } label: {
                        swatch(color: color, isSelected: store.colorFilter == color.rawValue)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                store.colorFilter = -1
                dismiss()
            } label: {
                Text("OnHand.Colors.All")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.colorFilter < 0)
            .padding(.top, 8.0)
        }
        .navigationTitle("OnHand.Colors")
    }

    func swatch(color: OnHandColor, isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(color.background)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 15.0, weight: .heavy))
                    .foregroundStyle(color.foreground)
            }
        }
        .frame(height: 40.0)
        .overlay {
            Circle()
                .strokeBorder(isSelected ? Color.primary : Color.clear, lineWidth: 2.0)
        }
    }
}
