import SwiftUI

struct HarnessView: View {

    @Bindable var session: SharedBuysSession

    @State private var joinLink: String = ""
    @State private var itemName: String = ""
    @State private var itemCost: String = "1000"
    @State private var countdown: Int = 0
    @State private var delayedWrite: Task<Void, Never>?

    var body: some View {
        HSplitView {
            controls
                .frame(minWidth: 420, idealWidth: 460)
            room
                .frame(minWidth: 460)
        }
    }

    private var controls: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                status
                Divider()
                connection
                Divider()
                writes
                Divider()
                bluetooth
            }
            .padding(20)
        }
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Shared Buys Harness").font(.title2.bold())
            Text("A stand-in for a second phone: same ORBiT sync engine, same relay, same radio.")
                .font(.caption)
                .foregroundStyle(.secondary)
            LabeledContent("Status", value: statusText)
            LabeledContent("Device", value: session.deviceID.isEmpty ? "—" : session.deviceID)
            LabeledContent("Room", value: session.roomID ?? "—")
            LabeledContent("Actor", value: String(session.actorPID))
        }
        .font(.system(.body, design: .monospaced))
    }

    private var statusText: String {
        switch session.status {
        case .idle: "idle"
        case .connecting: "connecting"
        case .connected: "connected"
        case .offline(let reason): "offline — \(reason)"
        }
    }

    private var connection: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Relay", text: $session.relayBaseURL)
            TextField("Nickname", text: $session.nickname)
            HStack {
                Button("Start a session") { session.start(eventNumber: 0, nickname: session.nickname) }
                    .disabled(session.isActive)
                Button("Reconnect") { session.connect() }
                    .disabled(!session.isActive)
                Button("Leave", role: .destructive) { session.leave() }
                    .disabled(!session.isActive)
            }
            HStack {
                TextField("circles-app://buys-join?…", text: $joinLink)
                Button("Join") {
                    guard let url = URL(string: joinLink.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                        session.note("bad join link")
                        return
                    }
                    session.join(url: url, nickname: session.nickname)
                }
                .disabled(joinLink.isEmpty)
            }
            if let joinURL = session.joinURL {
                joinCode(joinURL)
            }
        }
        .textFieldStyle(.roundedBorder)
    }

    private func joinCode(_ url: URL) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if let code = QRCode.image(for: url.absoluteString, side: 160) {
                code
                    .interpolation(.none)
                    .frame(width: 160, height: 160)
                    .background(.white)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Scan this with the phone to put both on one list.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(url.absoluteString)
                    .font(.caption2.monospaced())
                    .textSelection(.enabled)
                    .lineLimit(4)
                Button("Copy join link") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url.absoluteString, forType: .string)
                }
            }
        }
    }

    private var writes: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Write").font(.headline)
            HStack {
                TextField("Item", text: $itemName)
                TextField("Cost", text: $itemCost).frame(width: 90)
                Button("Add") { add() }
                    .disabled(!session.isActive || itemName.isEmpty)
            }
            // The point of the delay: put the phone to sleep, then let the Mac write
            // with nobody touching it. What arrives on the lock screen came from the
            // relay's push, not from the app being awake.
            HStack {
                Button(countdown > 0 ? "Writing in \(countdown)s — cancel" : "Add in 10 seconds") {
                    if countdown > 0 { cancelDelayed() } else { addAfterDelay() }
                }
                .disabled(!session.isActive || (itemName.isEmpty && countdown == 0))
                Spacer()
                Button("Self test") { session.runSelfTest() }
            }
        }
        .textFieldStyle(.roundedBorder)
    }

    private var bluetooth: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bluetooth").font(.headline)
            Toggle("Carry changes over Bluetooth", isOn: $session.isBluetoothEnabled)
                .onChange(of: session.isBluetoothEnabled) { _, enabled in
                    if enabled { session.startBluetooth() } else { session.stopBluetooth() }
                }
            LabeledContent("Peers", value: String(session.bluetoothPeers))
            if !session.bluetoothNote.isEmpty {
                Text(session.bluetoothNote).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var room: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                Section("Items (\(session.items.count))") {
                    ForEach(session.items, id: \.id) { item in
                        HStack {
                            Text(mark(for: item)).font(.system(.body, design: .monospaced))
                            Text(item.name)
                            Spacer()
                            Text("¥\(item.cost)").foregroundStyle(.secondary)
                            Text(session.members[item.assignee ?? 0] ?? "—")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(.rect)
                        .onTapGesture { session.cycle(item) }
                    }
                }
                Section("Members (\(session.members.count))") {
                    ForEach(session.members.sorted(by: { $0.key < $1.key }), id: \.key) { pid, name in
                        HStack {
                            Text(name)
                            Spacer()
                            Text(String(pid)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Log") {
                    ForEach(Array(session.log.enumerated()), id: \.offset) { _, line in
                        Text(line).font(.caption.monospaced())
                    }
                }
            }
            .listStyle(.inset)
            HStack {
                Text("Your share ¥\(session.yourShare)")
                Spacer()
                Text("Group ¥\(session.groupTotal)")
            }
            .font(.callout)
            .padding(12)
        }
    }

    private func mark(for item: SharedBuyItem) -> String {
        switch item.status {
        case .bought: "[x]"
        case .cancelled: "[-]"
        default: "[ ]"
        }
    }

    private func add() {
        _ = session.addItem(name: itemName, cost: Int(itemCost) ?? 0, circleID: 1)
        itemName = ""
    }

    private func addAfterDelay() {
        countdown = 10
        delayedWrite = Task {
            while countdown > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                countdown -= 1
            }
            add()
        }
    }

    private func cancelDelayed() {
        delayedWrite?.cancel()
        delayedWrite = nil
        countdown = 0
    }
}
