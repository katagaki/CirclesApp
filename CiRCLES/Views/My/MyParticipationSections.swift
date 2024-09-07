//
//  MyParticipationSections.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

import Komponents
import SwiftUI

struct MyParticipationSections: View {

    var latestEvent: ComiketEvent
    var eventDates: [Int: Date]

    @State var isInitialLoadCompleted: Bool = false

    @AppStorage(wrappedValue: "", "My.Participation") var participation: String

    @State var participationState: [String: [String: String]] = [:]

    var body: some View {
        ForEach(Array(eventDates.keys).sorted(), id: \.self) { dayID in
            Section {
                HStack {
                    switch participationState[String(latestEvent.eventNumber)]?[String(dayID)] {
                    case "Early":
                        ListRow(image: "ListIcon.Ticket.Fami",
                                title: "Shared.Ticket.Early")
                    case "AMPM":
                        ListRow(image: "ListIcon.Ticket.Wristband.AMPM",
                                title: "Shared.Ticket.Wristband")
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
                            setParticipation(latestEvent.eventNumber, on: dayID, value: "")
                        }
                        Button("Shared.Ticket.Early", image: .menuIconTicketFami) {
                            setParticipation(latestEvent.eventNumber, on: dayID, value: "Early")
                        }
                        Button("Shared.Ticket.Wristband", image: .menuIconTicketWristbandAMPM) {
                            setParticipation(latestEvent.eventNumber, on: dayID, value: "AMPM")
                        }
                        Button("Shared.Ticket.Circle", image: .menuIconTicketWristbandCircle) {
                            setParticipation(latestEvent.eventNumber, on: dayID, value: "Circle")
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
                    Spacer()
                    if let date = eventDates[dayID] {
                        Text(date, style: .date)
                    }
                }
                .font(.body)
                .textCase(nil)
                .foregroundStyle(.primary)
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
}