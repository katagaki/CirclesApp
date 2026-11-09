import SwiftUI

struct MyAccountSection: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Events.self) var planner

    @AppStorage("My.LastKnownNickname") var lastKnownNickname: String?

    var name: String {
        if let lastKnownNickname, !lastKnownNickname.isEmpty {
            return lastKnownNickname
        } else if authenticator.effectiveOnlineState == .offline {
            return String(localized: "My.User.OfflineMode")
        } else {
            return ""
        }
    }

    var participationSummary: String {
        let days = planner.participation[String(planner.activeEventNumber)] ?? [:]
        let attending = days
            .compactMap { day, ticket -> (Int, String)? in
                guard let dayID = Int(day), let ticketName = ticketName(ticket) else { return nil }
                return (dayID, ticketName)
            }
            .sorted { $0.0 < $1.0 }
            .map { "\(String(localized: "Shared.\($0.0)th.Day")) \($0.1)" }
        if attending.isEmpty {
            return String(localized: "My.Account.NoParticipation")
        }
        return attending.joined(separator: " · ")
    }

    var body: some View {
        Section {
            NavigationLink(value: MyComiketPath.account) {
                HStack(spacing: 14.0) {
                    MyProfilePhoto()
                        .frame(width: 60.0, height: 60.0)
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text(name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        Text(participationSummary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 2.0)
            }
        }
    }

    func ticketName(_ ticket: String) -> String? {
        switch ticket {
        case "Early": String(localized: "Ticket.Early")
        case "ChangingRoom": String(localized: "Ticket.ChangingRoom")
        case "AM": String(localized: "Ticket.AM")
        case "PM": String(localized: "Ticket.PM")
        case "Circle": String(localized: "Ticket.Circle")
        default: nil
        }
    }
}
