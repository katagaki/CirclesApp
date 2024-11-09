//
//  MyEventNotifierSheet.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/15.
//

import Komponents
import SwiftUI
import UserNotifications

struct MyEventNotifierSheet: View {

    @Environment(\.dismiss) var dismiss

    var date: Date
    @Binding var day: Int?
    @Binding var participation: String?

    @State var notificationsToUpdate: [String: [NotificationItem]] = [:]

    var dateString: String {
        date.formatted(date: .numeric, time: .omitted)
    }

    var notificationsPrior: [String: [NotificationItem]] {
        if let day {
            return [
                "Early": [
                    NotificationItem(day: day, eventDate: date, participation: "Early", time: .hoursPrior4),
                    NotificationItem(day: day, eventDate: date, participation: "Early", time: .hoursPrior3),
                    NotificationItem(day: day, eventDate: date, participation: "Early", time: .hoursPrior2),
                    NotificationItem(day: day, eventDate: date, participation: "Early", time: .hoursPrior1),
                    NotificationItem(day: day, eventDate: date, participation: "Early", time: .minutesPrior30)
                ],
                "AM": [
                    NotificationItem(day: day, eventDate: date, participation: "AM", time: .hoursPrior3),
                    NotificationItem(day: day, eventDate: date, participation: "AM", time: .hoursPrior2),
                    NotificationItem(day: day, eventDate: date, participation: "AM", time: .hoursPrior1)
                ],
                "PM": [
                    NotificationItem(day: day, eventDate: date, participation: "PM", time: .hoursPrior3),
                    NotificationItem(day: day, eventDate: date, participation: "PM", time: .hoursPrior2),
                    NotificationItem(day: day, eventDate: date, participation: "PM", time: .hoursPrior1)
                ],
                "Circle": [
                    NotificationItem(day: day, eventDate: date, participation: "Circle", time: .hoursPrior3),
                    NotificationItem(day: day, eventDate: date, participation: "Circle", time: .hoursPrior2),
                    NotificationItem(day: day, eventDate: date, participation: "Circle", time: .hoursPrior1)
                ]
            ]
        } else {
            return [:]
        }
    }
    var notificationsOnStart: [String: [NotificationItem]] {
        if let day {
            return [
                "Early": [
                    NotificationItem(day: day, eventDate: date, participation: "Early", time: .start)
                ],
                "AM": [
                    NotificationItem(day: day, eventDate: date, participation: "AM", time: .start)
                ],
                "PM": [
                    NotificationItem(day: day, eventDate: date, participation: "PM", time: .start)
                ],
                "Circle": [
                    NotificationItem(day: day, eventDate: date, participation: "Circle", time: .start)
                ]
            ]
        } else {
            return [:]
        }
    }
    var notificationOnEnd: [String: [NotificationItem]] {
        if let day {
            return [
                "Early": [
                    NotificationItem(day: day, eventDate: date, participation: "Early", time: .endCircles),
                    NotificationItem(day: day, eventDate: date, participation: "Early", time: .endCorporate)
                ],
                "AM": [
                    NotificationItem(day: day, eventDate: date, participation: "AM", time: .endCircles),
                    NotificationItem(day: day, eventDate: date, participation: "AM", time: .endCorporate)
                ],
                "PM": [
                    NotificationItem(day: day, eventDate: date, participation: "PM", time: .endCircles),
                    NotificationItem(day: day, eventDate: date, participation: "PM", time: .endCorporate)
                ],
                "Circle": [
                    NotificationItem(day: day, eventDate: date, participation: "Circle", time: .endCircles),
                    NotificationItem(day: day, eventDate: date, participation: "Circle", time: .endCorporate)
                ]
            ]
        } else {
            return [:]
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .center, spacing: 16.0) {
                        Image(systemName: "bell.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 52.0, height: 52.0, alignment: .center)
                            .foregroundStyle(.red)
                        Text("Notifier.Explainer")
                            .frame(maxWidth: .infinity)
                    }
                    .padding(8.0)
                }
                if let participation, participation != "" {
                    if let notificationsPrior = notificationsPrior[participation] {
                        Section {
                            ForEach(notificationsPrior) { notification in
                                ListCheckbox(
                                    notification.title,
                                    description: notification.timeString,
                                    isChecked: isNotificationAdded(notification)
                                ) { isChecked in
                                    updateNotifications(isChecked, notification)
                                }
                            }
                        } header: {
                            ListSectionHeader(text: "Notifier.BeforeEvent")
                        }
                    }
                    if let notificationsOnStart = notificationsOnStart[participation] {
                        Section {
                            ForEach(notificationsOnStart) { notification in
                                ListCheckbox(
                                    notification.title,
                                    description: notification.timeString,
                                    isChecked: isNotificationAdded(notification)
                                ) { isChecked in
                                    updateNotifications(isChecked, notification)
                                }
                            }
                        } header: {
                            ListSectionHeader(text: "Notifier.StartOfEvent")
                        }
                    }
                    if let notificationOnEnd = notificationOnEnd[participation] {
                        Section {
                            ForEach(notificationOnEnd) { notification in
                                ListCheckbox(
                                    notification.title,
                                    description: notification.timeString,
                                    isChecked: isNotificationAdded(notification)
                                ) { isChecked in
                                    updateNotifications(isChecked, notification)
                                }
                            }
                        } header: {
                            ListSectionHeader(text: "Notifier.EndOfEvent")
                        }
                    }
                }
            }
            .navigationTitle(date.formatted(date: .long, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Shared.Cancel", role: .cancel) {
                        notificationsToUpdate.removeAll()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Shared.Save") {
                        Task {
                            await saveNotifications()
                        }
                    }
                }
            }
        }
        .task {
            await reloadNotifications()
        }
        .interactiveDismissDisabled()
    }

    func reloadNotifications() async {
        let center = UNUserNotificationCenter.current()
        let notifications = await center.pendingNotificationRequests()
        if notificationsToUpdate[dateString] == nil {
            notificationsToUpdate[dateString] = []
        }
        notifications.forEach { notification in
            let notificationItem = NotificationItem(notification.content.userInfo)
            if notificationItem.eventDate == self.date {
                notificationsToUpdate[dateString]?.append(notificationItem)
            }
        }
    }

    func saveNotifications() async {
        do {
            let center = UNUserNotificationCenter.current()
            let authorized = try await center.requestAuthorization(
                options: [.alert, .sound]
            )
            if authorized {
                let notifications = await center.pendingNotificationRequests()
                for notification in notifications {
                    let notificationItem = NotificationItem(notification.content.userInfo)
                    if notificationItem.eventDate == self.date {
                        center.removePendingNotificationRequests(withIdentifiers: [notification.identifier])
                    }
                }
                for notification in notificationsToUpdate[dateString] ?? [] {
                    if let notificationRequest = notification.requestObject() {
                        try await center.add(notificationRequest)
                    }
                }
                dismiss()
            } else {
                // TODO: Show message guiding user to Settings app
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    func isNotificationAdded(_ notification: NotificationItem) -> Bool {
        return notificationsToUpdate[dateString]?.contains(where: {$0.time == notification.time}) ?? false
    }

    func updateNotifications(_ isChecked: Bool, _ notification: NotificationItem) {
        if notificationsToUpdate[dateString] == nil {
            notificationsToUpdate[dateString] = []
        }
        if isChecked {
            notificationsToUpdate[dateString]?.append(notification)
        } else {
            notificationsToUpdate[dateString]?.removeAll(where: {$0.time == notification.time})
        }
    }

    func dateFromTime(_ timeString: String) -> Date? {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        if let time = timeFormatter.date(from: timeString) {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            var mergedComponents = DateComponents()
            mergedComponents.year = dateComponents.year
            mergedComponents.month = dateComponents.month
            mergedComponents.day = dateComponents.day
            mergedComponents.hour = timeComponents.hour
            mergedComponents.minute = timeComponents.minute
            if let date = calendar.date(from: mergedComponents) {
                return date
            }
        }
        return nil
    }
}
