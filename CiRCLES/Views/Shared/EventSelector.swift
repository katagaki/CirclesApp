//
//  EventSelector.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import SwiftUI

struct EventSelector: View {
    @Environment(AuthManager.self) var authManager
    @Environment(EventManager.self) var eventManager

    var body: some View {
        List {
            ForEach(eventManager.events, id: \.eventId) { event in
                Text(String(event.eventId))
            }
        }
        .task {
            if let token = authManager.token {
                await eventManager.getEvents(authToken: token)
            }
        }
    }
}
