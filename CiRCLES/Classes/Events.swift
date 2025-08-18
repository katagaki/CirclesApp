//
//  Planner.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/17.
//

import Foundation
import SwiftUI

@Observable
class Events {

    @ObservationIgnored let activeEventNumberKey = "Events.Active.Number"
    @ObservationIgnored let participationKey = "My.Participation"

    var eventData: WebCatalogEvent.Response?
    @ObservationIgnored var latestEvent: WebCatalogEvent.Response.Event?

    var activeEvent: WebCatalogEvent.Response.Event?
    @ObservationIgnored var activeEventNumberUserDefault: Int {
        get {
            if UserDefaults.standard.value(forKey: activeEventNumberKey) != nil {
                return UserDefaults.standard.integer(forKey: activeEventNumberKey)
            } else {
                return -1
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: activeEventNumberKey)
        }
    }
    var activeEventNumber: Int

    var isActiveEventLatest: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "Events.Active.IsLatest")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "Events.Active.IsLatest")
        }
    }

    @ObservationIgnored var participationUserDefault: [String: [String: String]] {
        get {
            let participationString: String? = UserDefaults.standard.string(forKey: participationKey)
            if let participationString,
               let participationJSONData = participationString.data(using: .utf8) {
                if let participationJSONDictionary = try? JSONSerialization.jsonObject(
                    with: participationJSONData,
                    options: []
                ) as? [String: [String: String]] {
                    return participationJSONDictionary
                }
            }
            return [:]
        }
        set {
            if let participationJSONData = try? JSONSerialization.data(
                withJSONObject: newValue, options: []
            ) {
                if let participationJSONString = String(data: participationJSONData, encoding: .utf8) {
                    UserDefaults.standard.set(participationJSONString, forKey: participationKey)
                }
            }
        }
    }
    var participation: [String: [String: String]]

    init() {
        if UserDefaults.standard.value(forKey: activeEventNumberKey) != nil {
            activeEventNumber = UserDefaults.standard.integer(forKey: activeEventNumberKey)
        } else {
            activeEventNumber = -1
        }
        if UserDefaults.standard.value(forKey: participationKey) != nil {
            let participationString: String? = UserDefaults.standard.string(forKey: participationKey)
            if let participationString,
               let participationJSONData = participationString.data(using: .utf8) {
                if let participationJSONDictionary = try? JSONSerialization.jsonObject(
                    with: participationJSONData,
                    options: []
                ) as? [String: [String: String]] {
                    participation = participationJSONDictionary
                } else {
                    participation = [:]
                    participationUserDefault = participation
                }
            } else {
                participation = [:]
                participationUserDefault = participation
            }
        } else {
            participation = [:]
            participationUserDefault = participation
        }
    }

    @MainActor
    func prepare(authToken: OpenIDToken) async {
        if let eventData, let latestEvent {
            // Set active event to latest event if active event number is not specified
            if activeEventNumber == -1 {
                activeEventNumber = latestEvent.number
                activeEventNumberUserDefault = activeEventNumber
                isActiveEventLatest = true
            }
            isActiveEventLatest = activeEventNumber == eventData.latestEventNumber

            // Set specified active event using active event number
            if let eventInList = eventData.list.first(where: {$0.number == activeEventNumber}) {
                activeEvent = WebCatalogEvent.Response.Event(
                    id: eventInList.id,
                    number: activeEventNumber
                )
            }
        } else {
            // Fetch event data from API
            eventData = await WebCatalog.events(authToken: authToken)
            latestEvent = eventData?.list.first(where: {$0.id == eventData?.latestEventID})
            await prepare(authToken: authToken)
        }
    }

    func updateActiveEvent(onlineState: OnlineState) {
        switch onlineState {
        case .online:
            if let eventData,
               let eventInList = eventData.list.first(where: {$0.number == activeEventNumber}) {
                activeEvent = WebCatalogEvent.Response.Event(
                    id: eventInList.id,
                    number: activeEventNumber
                )
            }
        case .offline:
            activeEvent = WebCatalogEvent.Response.Event(
                id: activeEventNumber,
                number: activeEventNumber
            )
        case .undetermined: break
        }
    }

    func participationInfo(for day: Int) -> String? {
        return participation[String(activeEventNumber)]?[String(day)]
    }

    func setParticipation(for day: Int, value: String) {
        var participationData: [String: String] = [:]
        if let existingParticipationData = participation[String(activeEventNumber)] {
            participationData = existingParticipationData
        } else {
            participation[String(activeEventNumber)] = participationData
        }
        participationData[String(day)] = value
        withAnimation(.smooth.speed(2.0)) {
            participation[String(activeEventNumber)] = participationData
        }
        participationUserDefault = participation
    }

}
