//
//  BuyItemRow.swift
//  CiRCLES
//
//  Created by Claude on 2026/03/24.
//

import SwiftUI
import AXiS

struct BuyItemRow: View {

    @Environment(Events.self) var planner

    let item: BuyItem
    @Binding var expandedImage: UIImage?
    let onReload: () -> Void

    var body: some View {
        HStack(spacing: 8.0) {
            thumbnail
            Button {
                var updated = item
                updated.status = item.status.next
                BuysDatabase.shared.updateItem(updated, eventNumber: planner.activeEventNumber)
                withAnimation(.smooth.speed(2.0)) {
                    onReload()
                }
            } label: {
                HStack(spacing: 8.0) {
                    Text(item.name)
                        .strikethrough(item.status == .cancelled)
                        .foregroundStyle(item.status == .cancelled ? .secondary : .primary)
                    Spacer()
                    Text("Buys.CostValue.\(item.cost)")
                        .foregroundStyle(.secondary)
                        .strikethrough(item.status == .cancelled)
                        .monospacedDigit()
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .font(.subheadline)
    }

    @ViewBuilder
    var thumbnail: some View {
        if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 36.0, height: 36.0)
                .clipShape(RoundedRectangle(cornerRadius: 6.0))
                .overlay { boughtOverlay }
                .onTapGesture {
                    expandedImage = uiImage
                }
        } else {
            Image(systemName: "photo")
                .font(.system(size: 14.0))
                .foregroundStyle(.secondary)
                .frame(width: 36.0, height: 36.0)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 6.0))
                .overlay { boughtOverlay }
        }
    }

    @ViewBuilder
    var boughtOverlay: some View {
        if item.status == .bought {
            Color.black.opacity(0.3)
                .clipShape(RoundedRectangle(cornerRadius: 6.0))
            Circle()
                .fill(Color.accentColor)
                .frame(width: 20.0, height: 20.0)
                .overlay {
                    Circle()
                        .strokeBorder(.white, lineWidth: 1.5)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10.0, weight: .bold))
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.3), radius: 2.0, y: 1.0)
        }
    }
}
