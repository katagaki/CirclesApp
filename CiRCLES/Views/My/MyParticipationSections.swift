//
//  MyParticipationSections.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

import EventKit
import Komponents
import SwiftUI

struct MyParticipationSections: View {

    @Environment(\.openURL) var openURL
    @Environment(Planner.self) var planner

    @Binding var eventTitle: String?
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
                                title: "Ticket.Early")
                    case "ChangingRoom":
                        ListRow(image: "ListIcon.Ticket.Fami",
                                title: "Ticket.ChangingRoom")
                    case "AM":
                        ListRow(image: "ListIcon.Ticket.Wristband.AMPM",
                                title: "Ticket.AM")
                    case "PM":
                        ListRow(image: "ListIcon.Ticket.Wristband.AMPM",
                                title: "Ticket.PM")
                    case "Circle":
                        ListRow(image: "ListIcon.Ticket.Wristband.Circle",
                                title: "Ticket.Circle")
                    default:
                        Text("My.Ticket.NotParticipating")
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0.0)
                    Menu {
                        Button("My.Ticket.NotParticipating") {
                            planner.setParticipation(for: dayID, value: "")
                        }
                        Button("Ticket.Early", image: .menuIconTicketFami) {
                            planner.setParticipation(for: dayID, value: "Early")
                        }
                        Button("Ticket.ChangingRoom", image: .menuIconTicketFami) {
                            planner.setParticipation(for: dayID, value: "ChangingRoom")
                        }
                        Button("Ticket.AM", image: .menuIconTicketWristbandAMPM) {
                            planner.setParticipation(for: dayID, value: "AM")
                        }
                        Button("Ticket.PM", image: .menuIconTicketWristbandAMPM) {
                            planner.setParticipation(for: dayID, value: "PM")
                        }
                        Button("Ticket.Circle", image: .menuIconTicketWristbandCircle) {
                            planner.setParticipation(for: dayID, value: "Circle")
                        }
                    } label: {
                        Text("My.Ticket.ChangeType")
                    }
                }
                .animation(.snappy.speed(2.0), value: planner.participation)
                if let eventTitle, let eventDates, let date = eventDates[dayID],
                   let participationInfo = planner.participationInfo(for: dayID),
                   participationInfo != "" {
                    Button("My.AddToCalendar") {
                        Task {
                            let eventStore = EKEventStore()
                            do {
                                // NOTE: Must use async/await function, using completion handler will crash SwiftUI app
                                let isEventStoreAccessGranted = try await eventStore.requestWriteOnlyAccessToEvents()

                                if isEventStoreAccessGranted {
                                    let event: EKEvent = EKEvent(eventStore: eventStore)

                                    let nthDay = String(localized: "Shared.\(dayID)th.Day")
                                    switch Locale.current.language.languageCode {
                                    case .japanese: event.title = "\(eventTitle)（\(nthDay)）"
                                    default: event.title = "\(eventTitle) (\(nthDay))"
                                    }

                                    var eventNotes: String = ""
                                    switch participationInfo {
                                    case "Early":
                                        event.startDate = Calendar.current.date(
                                            bySettingHour: 10, minute: 30, second: 0, of: date
                                        )
                                        eventNotes += String(localized: "Ticket.Early")
                                    case "ChangingRoom":
                                        event.startDate = Calendar.current.date(
                                            bySettingHour: 11, minute: 0, second: 0, of: date
                                        )
                                        eventNotes += String(localized: "Ticket.ChangingRoom")
                                    case "AM":
                                        event.startDate = Calendar.current.date(
                                            bySettingHour: 11, minute: 0, second: 0, of: date
                                        )
                                        eventNotes += String(localized: "Ticket.AM")
                                    case "PM":
                                        event.startDate = Calendar.current.date(
                                            bySettingHour: 12, minute: 30, second: 0, of: date
                                        )
                                        eventNotes += String(localized: "Ticket.PM")
                                    case "Circle":
                                        event.startDate = Calendar.current.date(
                                            bySettingHour: 8, minute: 0, second: 0, of: date
                                        )
                                        eventNotes += String(localized: "Ticket.Circle")
                                    default: break
                                    }
                                    eventNotes += "\n\nhttps://www.comiket.co.jp/"
                                    event.notes = eventNotes

                                    event.endDate = Calendar.current.date(
                                        bySettingHour: 17, minute: 0, second: 0, of: date
                                    )

                                    event.url = URL(string: "circles-app://")
                                    event.calendar = eventStore.defaultCalendarForNewEvents
                                    try eventStore.save(event, span: .thisEvent)
                                    try eventStore.commit()
                                    openURL(URL(string: "calshow:\(date.timeIntervalSinceReferenceDate)")!)
                                }
                            } catch {
                                debugPrint(error.localizedDescription)
                            }
                        }
                    }
                }
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
