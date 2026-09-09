//
//  HarnessCLI.swift
//  MacHarness
//

import Foundation

/// The harness without the window: the stand-in device, driven from a terminal.
enum HarnessCLI {

    static func run(arguments: [String]) {
        let options = Options(arguments)
        if options.wantsHelp {
            print(usage)
            return
        }
        let session = MainActor.assumeIsolated { SharedBuysSession() }
        Task { @MainActor in
            await drive(session, with: options)
            exit(0)
        }
        RunLoop.main.run()
    }

    @MainActor
    private static func drive(_ session: SharedBuysSession, with options: Options) async {
        session.adoptIdentity()
        session.nickname = options.nickname
        session.relayBaseURL = options.relay
        session.isBluetoothEnabled = options.bluetooth

        if let link = options.join, let url = URL(string: link) {
            session.join(url: url, nickname: options.nickname)
        } else if options.start {
            session.start(eventNumber: 0, nickname: options.nickname)
        } else {
            session.restore()
        }
        guard session.isActive else {
            say("no session — pass --start, --join <link>, or leave a stored session behind")
            return
        }
        say("room \(session.roomID ?? "?") as \(session.deviceID)")
        if let joinURL = session.joinURL { say("join \(joinURL.absoluteString)") }

        var drained = 0
        let deadline = Date().addingTimeInterval(options.watch)
        var written = options.item == nil
        let writeAt = Date().addingTimeInterval(options.after)

        while Date() < deadline {
            drained = drain(session.log, from: drained)
            if !written, Date() >= writeAt, let item = options.item {
                _ = session.addItem(name: item, cost: options.cost, circleID: 1)
                say("wrote \(item) at ¥\(options.cost)")
                written = true
            }
            try? await Task.sleep(for: .milliseconds(200))
        }
        _ = drain(session.log, from: drained)
        report(session)
        flush(session)
    }

    /// The session saves through a detached task, which `exit` does not wait for.
    /// A run that joined a room and then lost it on the way out is worse than useless.
    @MainActor
    private static func flush(_ session: SharedBuysSession) {
        guard let sessionKey = session.sessionKey else { return }
        SharedBuysStore.save(
            SharedBuysSnapshot(
                sessionKey: sessionKey,
                deviceID: session.deviceID,
                eventNumber: session.eventNumber,
                lastSeq: session.lastSeq,
                changes: session.changes
            )
        )
    }

    @MainActor
    private static func report(_ session: SharedBuysSession) {
        say("status \(session.status)")
        say("items \(session.items.count), members \(session.members.count)")
        for item in session.items {
            let mark = item.status == .bought ? "x" : (item.status == .cancelled ? "-" : " ")
            say("  [\(mark)] \(item.name)  ¥\(item.cost)  \(session.members[item.assignee ?? 0] ?? "—")")
        }
    }

    /// The session log grows at the front; print whatever appeared since last time.
    private static func drain(_ log: [String], from printed: Int) -> Int {
        guard log.count > printed else { return printed }
        for line in log.prefix(log.count - printed).reversed() { say(line) }
        return log.count
    }

    private static func say(_ message: String) {
        print("[harness] \(message)")
        fflush(stdout)
    }

    private struct Options {
        var relay = "ws://127.0.0.1:8787"
        var nickname = "Mac"
        var join: String?
        var start = false
        var item: String?
        var cost = 1000
        var after: TimeInterval = 0
        var watch: TimeInterval = 10
        var bluetooth = false
        var wantsHelp = false

        init(_ arguments: [String]) {
            var index = 0
            while index < arguments.count {
                let argument = arguments[index]
                let next = index + 1 < arguments.count ? arguments[index + 1] : nil
                switch argument {
                case "--relay": relay = next ?? relay; index += 1
                case "--nickname": nickname = next ?? nickname; index += 1
                case "--join": join = next; index += 1
                case "--start": start = true
                case "--add": item = next; index += 1
                case "--cost": cost = Int(next ?? "") ?? cost; index += 1
                case "--after": after = Double(next ?? "") ?? after; index += 1
                case "--watch": watch = Double(next ?? "") ?? watch; index += 1
                case "--bluetooth": bluetooth = true
                case "--help", "-h": wantsHelp = true
                default: break
                }
                index += 1
            }
            watch = max(watch, after + 2)
        }
    }

    private static let usage = """
    MacHarness --cli [options]

      --relay <url>       relay to dial (default ws://127.0.0.1:8787)
      --nickname <name>   how this stand-in appears in the member list (default Mac)
      --start             start a new room and print its join link
      --join <link>       join a room from a circles-app://buys-join link
      --add <name>        write one item
      --cost <yen>        what it costs (default 1000)
      --after <seconds>   wait before writing — the pause where you lock the phone
      --watch <seconds>   how long to stay connected (default 10)
      --bluetooth         bring the radio up as well as the socket

    With none of --start or --join it reuses the stored session, the same one the
    window uses.
    """
}
