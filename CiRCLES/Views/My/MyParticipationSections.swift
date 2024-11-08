//
//  MyParticipationSections.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

import Komponents
import SwiftUI

struct MyParticipationSections: View {

    var eventDates: [Int: Date]

    @State var isInitialLoadCompleted: Bool = false
    @Binding var dateForNotifier: Date?
    @Binding var dayForNotifier: Int?
    @Binding var participationForNotifier: String?

    @Binding var activeEventNumber: Int

    @AppStorage(wrappedValue: "", "My.Participation") var participation: String
    @State var participationState: [String: [String: String]] = [:]

    var body: some View {
        ForEach(Array(eventDates.keys).sorted(), id: \.self) { dayID in
            Section {
                HStack {
                    switch participationState[String(activeEventNumber)]?[String(dayID)] {
                    case "Early":
                        ListRow(image: "ListIcon.Ticket.Fami",
                                title: "Shared.Ticket.Early")
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
                            setParticipation(activeEventNumber, on: dayID, value: "")
                        }
                        Button("Shared.Ticket.Early", image: .menuIconTicketFami) {
                            setParticipation(activeEventNumber, on: dayID, value: "Early")
                        }
                        Button("Shared.Ticket.AM", image: .menuIconTicketWristbandAMPM) {
                            setParticipation(activeEventNumber, on: dayID, value: "AM")
                        }
                        Button("Shared.Ticket.PM", image: .menuIconTicketWristbandAMPM) {
                            setParticipation(activeEventNumber, on: dayID, value: "PM")
                        }
                        Button("Shared.Ticket.Circle", image: .menuIconTicketWristbandCircle) {
                            setParticipation(activeEventNumber, on: dayID, value: "Circle")
                        }
                    } label: {
                        Text("My.Ticket.ChangeType")
                    }
                }
                .animation(.snappy.speed(2.0), value: participationState)
            } header: {
                HStack {
                    Text("Shared.\(dayID)th.Day")
                        .fontWeight(.bold)
                    // This is deprecated, but is used because foregroundStyle does not work
                        .foregroundColor(.primary)
                    if let date = eventDates[dayID] {
                        Text(date, style: .date)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Shared.RemindMe", systemImage: "bell") {
                            participationForNotifier = participationState[String(activeEventNumber)]?[String(dayID)]
                            dayForNotifier = dayID
                            dateForNotifier = date
                        }
                        .disabled(!isAllowedToSetNotification(date) ||
                                  participationState[String(activeEventNumber)]?[String(dayID)] == "")
                    }
                }
                .font(.body)
                .textCase(nil)
            }
        }
        .onAppear {
            debugPrint("Restoring My participation")
            if !isInitialLoadCompleted {
                loadParticipation()
                isInitialLoadCompleted = true
            }
        }
        .onChange(of: participationState) { _, _ in
            if isInitialLoadCompleted {
                saveParticipation()
            }
        }
        .onChange(of: eventDates) { _, _ in
            loadParticipation()
        }
    }

    func loadParticipation() {
        if let participationJSONData = participation.data(using: .utf8) {
            if let participationJSONDictionary = try? JSONSerialization.jsonObject(
                with: participationJSONData,
                options: []
            ) as? [String: [String: String]] {
                participationState = participationJSONDictionary
            }
        }
    }

    func saveParticipation() {
        if let participationJSONData = try? JSONSerialization.data(
            withJSONObject: participationState,
            options: []
        ) {
            if let participationJSONString = String(data: participationJSONData, encoding: .utf8) {
                participation = participationJSONString
            }
        }
    }

    func setParticipation(_ eventNumber: Int, on day: Int, value: String) {
        var participationData: [String: String] = [:]
        if let existingParticipationData = participationState[String(eventNumber)] {
            participationData = existingParticipationData
        } else {
            participationState[String(eventNumber)] = participationData
        }
        participationData[String(day)] = value
        withAnimation(.snappy.speed(2.0)) {
            participationState[String(eventNumber)] = participationData
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
