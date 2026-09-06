//
//  SharedBuysSession+Totals.swift
//  CiRCLES
//

import Foundation

@MainActor
extension SharedBuysSession {

    func adoptIdentity() {
        let storedPID = UserDefaults.standard.integer(forKey: "My.LastKnownPID")
        let storedNickname = UserDefaults.standard.string(forKey: "My.LastKnownNickname") ?? ""
        if storedPID != 0 { actorPID = storedPID }
        if !storedNickname.isEmpty { nickname = storedNickname }
        if nickname.isEmpty { nickname = String(localized: "Buys.Shared.You") }
    }

    var yourShare: Int {
        items.filter { $0.assignee == actorPID && $0.status != .cancelled }
            .reduce(0) { $0 + $1.cost }
    }

    var groupTotal: Int {
        items.filter { $0.status != .cancelled }.reduce(0) { $0 + $1.cost }
    }

    var hasUnsentChanges: Bool {
        if case .connected = status { return false }
        return bluetoothPeers == 0 && !changes.isEmpty
    }
}
