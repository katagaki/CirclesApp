//
//  DatePicker.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/09/21.
//

import SwiftData
import SwiftUI
import AXiS

struct DatePicker: View {
    @Environment(UserSelections.self) var selections
    @Environment(Unifier.self) var unifier

    var body: some View {
        Button {
            withAnimation(.smooth(duration: 0.25)) {
                unifier.presentedControlMenu = .date
            }
        } label: {
            HStack(spacing: 10.0) {
                if let selectedDate = selections.date {
                    VStack(alignment: .leading) {
                        Text("Shared.\(selectedDate.id)th.Day")
                            .font(.caption)
                            .bold()
                            .foregroundStyle(.primary)
                        Text(selectedDate.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Shared.Placeholder.NoDay")
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct DateSelectorMenu: View {
    @Environment(UserSelections.self) var selections
    @Environment(Database.self) var database

    let carouselWidth: CGFloat = 268.0
    let cardHeight: CGFloat = 64.0
    let cardCornerRadius: CGFloat = ControlMenuMetrics.contentCornerRadius

    var dates: [ComiketDate] {
        database.dates()
    }

    var body: some View {
        ControlMenu(contentWidth: carouselWidth, isContentEdgeToEdge: true) { close in
            ScrollView(.horizontal) {
                HStack(spacing: 8.0) {
                    ForEach(dates, id: \.id) { date in
                        card(for: date, close: close)
                    }
                }
                // Inside the scroll view so cards scroll to the menu's edges.
                .padding(.horizontal, ControlMenuMetrics.padding)
                .frame(minWidth: carouselWidth + ControlMenuMetrics.padding * 2.0, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    @ViewBuilder
    func card(for date: ComiketDate, close: @escaping () -> Void) -> some View {
        let isSelected = selections.date == date
        Button {
            selections.date = date
            close()
        } label: {
            VStack(spacing: 2.0) {
                Text("Shared.\(date.id)th.Day")
                    .font(.system(size: 16.0, weight: .bold, design: .rounded))
                Text("(\(date.date.formatted(.dateTime.weekday(.abbreviated))))")
                    .font(.system(size: 13.0, weight: .medium, design: .rounded))
            }
            .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight)
            .background(
                isSelected ? Color.accentColor : Color.gray.opacity(0.3),
                in: .rect(cornerRadius: cardCornerRadius, style: .continuous)
            )
        }
        .buttonStyle(DateCardButtonStyle(cornerRadius: cardCornerRadius))
        .frame(minWidth: 56.0)
    }
}

struct DateCardButtonStyle: ButtonStyle {

    let cornerRadius: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                Color.black
                    .opacity(configuration.isPressed ? 0.25 : 0.0)
            }
            .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
    }
}
