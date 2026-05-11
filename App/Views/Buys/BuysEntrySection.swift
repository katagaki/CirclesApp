//
//  BuysEntrySection.swift
//  CiRCLES
//
//  Created by Claude on 2026/03/24.
//

import SwiftUI
import AXiS

struct BuysEntrySection: View {

    @Environment(Database.self) var database
    @Environment(Unifier.self) var unifier

    let entry: BuyEntry
    @Binding var expandedImage: UIImage?
    let onReload: () -> Void

    var body: some View {
        let circle = database.circles([entry.circleID]).first

        Section {
            ForEach(entry.items.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }) { item in
                BuyItemRow(item: item, expandedImage: $expandedImage, onReload: onReload)
            }
        } header: {
            if let circle {
                Button {
                    unifier.append(.circleDetail(circle: circle))
                } label: {
                    HStack(spacing: 6.0) {
                        Text(circle.circleName)
                            .fontWeight(.semibold)
                        if let spaceName = circle.spaceName() {
                            CircleBlockPill(LocalizedStringKey(spaceName))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text("Buys.UnknownCircle.\(entry.circleID)")
            }
        }
    }
}
