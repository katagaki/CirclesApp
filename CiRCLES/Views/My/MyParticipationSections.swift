//
//  MyParticipationSections.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

import Komponents
import SwiftUI

struct MyParticipationSections: View {

    @Environment(Planner.self) var planner

    @Binding var eventDates: [Int: Date]?
    @Binding var dateForNotifier: Date?
    @Binding var dayForNotifier: Int?
    @Binding var participationForNotifier: String?

    @State var isInitialLoadCompleted: Bool = false

    var body: some View {
        ForEach(Array((eventDates ?? [:]).keys).sorted(), id: \.self) { dayID in
            Section {
                HStack {
                    switch planner.participationInfo(for: dayID) {
                    case "Early":
                        ListRow(image: "ListIcon.Ticket.Fami",
                                title: "Shared.Ticket.Early")
                    case "ChangingRoom":
                        ListRow(image: "ListIcon.Ticket.Fami",
                                title: "Shared.Ticket.ChangingRoom")
                    case "AM":
                        ListRow(image: "ListIcon.Ticket.Wristband.AMPM",
                                title: "Shared.Ticket.AM")
                    case "PM":
                        ListRow(image: "ListIcon.Ticket.Wristband.AMPM",
                                title: "Shared.Ticket.PM")
                    case "Circle":
                        ListRow(image: "ListIcon.Ticket.Wristband.Circle",
                                title: "Shared.Ticket.Circle")
                    default:
                        Text("My.Ticket.NotParticipating")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Menu {
                        Button("My.Ticket.NotParticipating") {
                            planner.setParticipation(for: dayID, value: "")
                        }
                        Button("Shared.Ticket.Early", image: .menuIconTicketFami) {
                            planner.setParticipation(for: dayID, value: "Early")
                        }
                        Button("Shared.Ticket.ChangingRoom", image: .menuIconTicketFami) {
                            planner.setParticipation(for: dayID, value: "ChangingRoom")
                        }
                        Button("Shared.Ticket.AM", image: .menuIconTicketWristbandAMPM) {
                            planner.setParticipation(for: dayID, value: "AM")
                        }
                        Button("Shared.Ticket.PM", image: .menuIconTicketWristbandAMPM) {
                            planner.setParticipation(for: dayID, value: "PM")
                        }
                        Button("Shared.Ticket.Circle", image: .menuIconTicketWristbandCircle) {
                            planner.setParticipation(for: dayID, value: "Circle")
                        }
                    } label: {
                        Text("My.Ticket.ChangeType")
                    }
                }
                .animation(.snappy.speed(2.0), value: planner.participation)
            } header: {
                HStack {
                    Text("Shared.\(dayID)th.Day")
                        .fontWeight(.bold)
                    // This is deprecated, but is used because foregroundStyle does not work
                        .foregroundColor(.primary)
                    if let eventDates, let date = eventDates[dayID] {
                        Text(date, style: .date)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Shared.RemindMe", systemImage: "bell") {
                            participationForNotifier = planner.participationInfo(for: dayID)
                            dayForNotifier = dayID
                            dateForNotifier = date
                        }
                        .disabled(!isAllowedToSetNotification(date) ||
                                  planner.participationInfo(for: dayID) == nil ||
                                  planner.participationInfo(for: dayID) == "")
                    }
                }
                .font(.body)
                .textCase(nil)
            }
        }
        .onAppear {
            if !isInitialLoadCompleted {
                isInitialLoadCompleted = true
            }
        }
    }

    func isAllowedToSetNotification(_ date: Date) -> Bool {
        var calendar = Calendar.current
        let dateFormatter = DateFormatter()
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")

        var components = calendar.dateComponents([.year, .month, .day], from: Date.now)
        components.hour = 17
        components.minute = 0

        if let dateToday = calendar.date(from: components) {
            return dateToday < date
        }
        return false
    }
}
