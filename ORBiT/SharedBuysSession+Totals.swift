import Foundation

@MainActor
public extension SharedBuysSession {

    public func adoptIdentity() {
        isGuest = UserDefaults.standard.bool(forKey: Self.guestModeKey)
        // A guest has no circle.ms identity to adopt, and the WebCatalog nickname of
        // whoever used this phone before them is not theirs to wear.
        if isGuest {
            actorPID = Self.localActorID()
            nickname = Self.guestNickname()
            return
        }
        let storedPID = UserDefaults.standard.integer(forKey: "My.LastKnownPID")
        let storedNickname = UserDefaults.standard.string(forKey: "My.LastKnownNickname") ?? ""
        actorPID = storedPID != 0 ? storedPID : Self.localActorID()
        if !storedNickname.isEmpty { nickname = storedNickname }
        if nickname.isEmpty { nickname = String(localized: "Buys.Shared.You") }
    }

    /// The guest's minted name, kept so the same phone is the same member across
    /// relaunches and across rooms.
    static func guestNickname() -> String {
        if let existing = UserDefaults.standard.string(forKey: Self.guestNicknameKey),
           !existing.isEmpty {
            return existing
        }
        let minted = SharedBuysGuestName.generate()
        UserDefaults.standard.set(minted, forKey: Self.guestNicknameKey)
        return minted
    }

    /// A stable stand-in identity for someone who is not signed in.
    ///
    /// Leaving `actorPID` at 0 made every signed-out member the same actor: `members`
    /// collapsed to a single entry, every item looked assigned to you, and `yourShare`
    /// equalled `groupTotal` on both phones. Negative so it cannot collide with a real
    /// circle.ms PID, and stored so it survives relaunches.
    static func localActorID() -> Int {
        let key = "My.LocalActorID"
        let existing = UserDefaults.standard.integer(forKey: key)
        if existing != 0 { return existing }
        let minted = -Int(UInt32.random(in: 1...UInt32.max))
        UserDefaults.standard.set(minted, forKey: key)
        return minted
    }

    public var yourShare: Int {
        items.filter { $0.assignee == actorPID && $0.status != .cancelled }
            .reduce(0) { $0 + $1.cost }
    }

    public var groupTotal: Int {
        items.filter { $0.status != .cancelled }.reduce(0) { $0 + $1.cost }
    }

    public var hasUnsentChanges: Bool {
        if case .connected = status { return false }
        return bluetoothPeers == 0 && !changes.isEmpty
    }
}
