//
//  Notification.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/15.
//

import Foundation
import SwiftUICore
import UserNotifications

struct NotificationItem: Identifiable {
    var id: String = UUID().uuidString
    var day: Int
    var eventDate: Date
    var participation: String
    var time: Time

    init(day: Int, eventDate: Date, participation: String, time: Time) {
        self.day = day
        #if DEBUG
        self.eventDate = Date.now.advanced(by: TimeInterval(21600))
        #else
        self.eventDate = eventDate
        #endif
        self.participation = participation
        self.time = time
    }

    init(_ userInfo: [AnyHashable: Any]) {
        if let id = userInfo["id"] as? String,
           let day = userInfo["day"] as? Int,
            let eventDate = userInfo["eventDate"] as? Date,
            let participation = userInfo["participation"] as? String,
            let time = userInfo["time"] as? String {
            self.id = id
            self.day = day
            self.eventDate = eventDate
            self.participation = participation
            self.time = Time(rawValue: time)!
        } else {
            self.day = -1
            self.eventDate = Date()
            self.participation = ""
            self.time = .start
        }
    }

    var title: LocalizedStringKey {
        switch time {
        case .hoursPrior4:
            return LocalizedStringKey("Notifier.Prior.4H")
        case .hoursPrior3:
            return LocalizedStringKey("Notifier.Prior.3H")
        case .hoursPrior2:
            return LocalizedStringKey("Notifier.Prior.2H")
        case .hoursPrior1:
            return LocalizedStringKey("Notifier.Prior.1H")
        case .minutesPrior30:
            return LocalizedStringKey("Notifier.Prior.30Min")
        case .start:
            return LocalizedStringKey("Notifier.Entry")
        case .endCircles:
            return LocalizedStringKey("Notifier.CircleEnd")
        case .endCorporate:
            return LocalizedStringKey("Notifier.CorporateEnd")
        }
    }

    var timeString: LocalizedStringKey {
        var hour: Int?
        var minutes: Int?
        switch participation {
        case "Early":
            hour = 10
            minutes = 30
        case "AM":
            hour = 11
            minutes = 0
        case "PM":
            hour = 12
            minutes = 30
        case "Circle":
            hour = 8
            minutes = 0
        default: break
        }
        if let hour, let minutes {
            switch time {
            case .hoursPrior4:
                return "\(String(format: "%02d", hour - 4)):\(String(format: "%02d", minutes))"
            case .hoursPrior3:
                return "\(String(format: "%02d", hour - 3)):\(String(format: "%02d", minutes))"
            case .hoursPrior2:
                return "\(String(format: "%02d", hour - 2)):\(String(format: "%02d", minutes))"
            case .hoursPrior1:
                return "\(String(format: "%02d", hour - 1)):\(String(format: "%02d", minutes))"
            case .minutesPrior30:
                if minutes >= 30 {
                    return "\(String(format: "%02d", hour)):\(String(format: "%02d", minutes - 30))"
                } else {
                    return "\(String(format: "%02d", hour - 1)):\(String(format: "%02d", minutes + 60 - 30))"
                }
            case .start:
                return "10:30"
            case .endCircles:
                return "16:00"
            case .endCorporate:
                return "17:00"
            }
        }
        return ""
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    func requestObject() -> UNNotificationRequest? {
        // Configure notification contents
        let contents = UNMutableNotificationContent()
        contents.userInfo = [
            "id": id,
            "day": day,
            "eventDate": eventDate,
            "participation": participation,
            "time": time.rawValue
        ]
        switch time {
        case .hoursPrior4, .hoursPrior3, .hoursPrior2, .hoursPrior1, .minutesPrior30:
            contents.title = String(localized: "Notifier.\(day).Prior.Title")
        case .start:
            contents.title = String(localized: "Notifier.\(day).StartOfEvent.Title")
        case .endCircles, .endCorporate:
            contents.title = String(localized: "Notifier.\(day).EndOfEvent.Title")
        }
        switch time {
        case .hoursPrior4:
            contents.body = String(localized: "Notifier.Prior.4H.Body")
        case .hoursPrior3:
            contents.body = String(localized: "Notifier.Prior.3H.Body")
        case .hoursPrior2:
            contents.body = String(localized: "Notifier.Prior.2H.Body")
        case .hoursPrior1:
            contents.body = String(localized: "Notifier.Prior.1H.Body")
        case .minutesPrior30:
            contents.body = String(localized: "Notifier.Prior.30Min.Body")
        case .start:
            contents.body = String(localized: "Notifier.StartOfEvent.Body")
        case .endCircles:
            contents.body = String(localized: "Notifier.CircleEnd.Body")
        case .endCorporate:
            contents.body = String(localized: "Notifier.CorporateEnd.Body")
        }
        contents.sound = UNNotificationSound.default

        // Configure notification time
        var trigger: UNCalendarNotificationTrigger?
        let calendar = Calendar.current
        var dateComponents: DateComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: eventDate
        )
        switch time {
        case .hoursPrior4, .hoursPrior3, .hoursPrior2, .hoursPrior1, .minutesPrior30:
            dateComponents.hour = 10
            dateComponents.minute = 30
            switch time {
            case .hoursPrior4:
                if let hour = dateComponents.hour {
                    dateComponents.hour = hour - 4
                }
            case .hoursPrior3:
                if let hour = dateComponents.hour {
                    dateComponents.hour = hour - 3
                }
            case .hoursPrior2:
                if let hour = dateComponents.hour {
                    dateComponents.hour = hour - 2
                }
            case .hoursPrior1:
                if let hour = dateComponents.hour {
                    dateComponents.hour = hour - 1
                }
            case .minutesPrior30:
                if let hour = dateComponents.hour,
                    let minutes = dateComponents.minute {
                    if minutes >= 30 {
                        dateComponents.minute = minutes - 30
                    } else {
                        dateComponents.hour = hour - 1
                        dateComponents.minute = (minutes + 60) - 30
                    }
                }
            default: break
            }
        case .start:
            dateComponents.hour = 10
            dateComponents.minute = 30
        case .endCircles:
            dateComponents.hour = 16
            dateComponents.minute = 0
        case .endCorporate:
            dateComponents.hour = 17
            dateComponents.minute = 0
        }
        if let identifier = identifier(from: dateComponents) {
            // Configure notification trigger
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            return UNNotificationRequest(
                identifier: identifier,
                content: contents,
                trigger: trigger
            )
        }
        return nil
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    func identifier(from components: DateComponents) -> String? {
        if let year = components.year, let month = components.month, let day = components.day,
           let hour = components.hour, let minute = components.minute {
            return "\(year)-\(month)-\(day)-\(hour)-\(minute)"
        }
        return nil
    }

    enum Time: String, Codable {
        case hoursPrior4
        case hoursPrior3
        case hoursPrior2
        case hoursPrior1
        case minutesPrior30
        case start
        case endCircles
        case endCorporate
    }
}
