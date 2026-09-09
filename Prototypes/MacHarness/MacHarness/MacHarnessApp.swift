//
//  MacHarnessApp.swift
//  MacHarness
//

import Foundation
import SwiftUI

/// The window when you want to watch, `--cli` when you want to script it.
///
/// Testing a push means writing from the other device while nobody is touching either
/// one, which is a script, not a click.
@main
struct MacHarnessMain {
    static func main() {
        if CommandLine.arguments.contains("--cli") {
            HarnessCLI.run(arguments: CommandLine.arguments)
            return
        }
        MacHarnessApp.main()
    }
}

struct MacHarnessApp: App {

    @State private var session = SharedBuysSession()

    /// The session log, mirrored where it can be watched with `tail -f` while your
    /// hands are on the phone. Launched from Finder there is no console to print to,
    /// so it goes to a file as well as stderr.
    static let logFile = FileManager.default
        .homeDirectoryForCurrentUser
        .appending(path: "Library/Logs/MacHarness.log")

    private func mirrorLog() async {
        var printed = 0
        emit("harness ready")
        while !Task.isCancelled {
            let lines = session.log
            if lines.count > printed {
                for line in lines.prefix(lines.count - printed).reversed() { emit(line) }
                printed = lines.count
            }
            try? await Task.sleep(for: .milliseconds(250))
        }
    }

    private func emit(_ line: String) {
        let stamped = "[\(Date().formatted(date: .omitted, time: .standard))] \(line)\n"
        FileHandle.standardError.write(Data(stamped.utf8))
        guard let handle = try? FileHandle(forWritingTo: Self.logFile) else {
            try? Data(stamped.utf8).write(to: Self.logFile)
            return
        }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: Data(stamped.utf8))
    }

    var body: some Scene {
        WindowGroup("Shared Buys Harness") {
            HarnessView(session: session)
                .frame(minWidth: 940, minHeight: 620)
                .task { await mirrorLog() }
                .task {
                    session.adoptIdentity()
                    if session.nickname.isEmpty { session.nickname = "Mac" }
                    session.restore()
                }
        }
        .defaultSize(width: 1040, height: 700)
    }
}
