//
//  DatePicker.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/09/21.
//

import SwiftData
import SwiftUI

struct DatePicker: View {
    @Environment(UserSelections.self) var selections
    @Environment(Database.self) var database
    @State var dates: [ComiketDate] = []

    var body: some View {
        Menu {
            ForEach(dates, id: \.id) { date in
                Button("Shared.\(date.id)th.Day",
                       systemImage: selections.date == date ? "checkmark" : "") {
                    selections.date = date
                }
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
        .task {
            dates = database.dates()
        }
    }
}
