//
//  SharedBuysDebugView.swift
//  CiRCLES
//

import CoreImage.CIFilterBuiltins
import SwiftUI

struct SharedBuysDebugView: View {

    @Environment(SharedBuysSession.self) var session
    @Environment(\.dismiss) var dismiss

    @State var itemName: String = ""
    @State var itemCost: String = "1000"
    @State var joinLink: String = ""
    @State var nickname: String = "Tester"

    var body: some View {
        @Bindable var session = session
        NavigationStack {
            List {
                Section {
                    LabeledContent("Status", value: statusText)
                    LabeledContent("Device", value: session.deviceID.isEmpty ? "—" : session.deviceID)
                    LabeledContent("Room", value: session.roomID ?? "—")
                    LabeledContent("Bluetooth peers", value: "\(session.bluetoothPeers)")
                    LabeledContent("Live Activities", value: "\(session.activityCount)")
                    LabeledContent("Activities enabled", value: session.activitiesEnabled ? "yes" : "no")
                    TextField("Relay", text: $session.relayBaseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("PID", value: $session.actorPID, format: .number)
                        .keyboardType(.numberPad)
                    TextField("Nickname", text: $nickname)
                } header: {
                    Text("Session")
                }

                if session.isActive {
                    Section {
                        if let joinURL = session.joinURL {
                            VStack(spacing: 10.0) {
                                qrImage(joinURL.absoluteString)
                                Text(joinURL.absoluteString)
                                    .font(.caption2)
                                    .monospaced()
                                    .textSelection(.enabled)
                                    .lineLimit(3)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        Button("Reconnect") { session.connect() }
                        Button("Leave", role: .destructive) { session.leave() }
                    } header: {
                        Text("Join link")
                    }

                    Section {
                        HStack {
                            TextField("Item", text: $itemName)
                            TextField("Cost", text: $itemCost)
                                .frame(width: 70.0)
                                .keyboardType(.numberPad)
                            Button("Add") {
                                session.addItem(
                                    name: itemName,
                                    cost: Int(itemCost) ?? 0,
                                    circleID: 1
                                )
                                itemName = ""
                            }
                            .disabled(itemName.isEmpty)
                        }
                        ForEach(session.items) { item in
                            Button {
                                session.cycle(item)
                            } label: {
                                HStack {
                                    Image(systemName: symbol(for: item))
                                    Text(item.name)
                                    Spacer()
                                    if let assignee = item.assignee {
                                        Text(session.members[assignee] ?? String(assignee))
                                            .foregroundStyle(.secondary)
                                    }
                                    Text("¥\(item.cost)")
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("Items (\(session.items.count))")
                    }

                    Section {
                        ForEach(session.changes.sorted { $0.seq < $1.seq }, id: \.id) { change in
                            Text("\(change.id)  \(String(describing: change.payload.kind))")
                                .font(.caption2)
                                .monospaced()
                        }
                    } header: {
                        Text("Changes (\(session.changes.count))")
                    }
                } else {
                    Section {
                        Button("Start a session") {
                            session.start(eventNumber: 0, nickname: nickname)
                        }
                        TextField("Join link", text: $joinLink)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Join") {
                            if let url = URL(string: joinLink) {
                                session.join(url: url, nickname: nickname)
                            }
                        }
                        .disabled(joinLink.isEmpty)
                    }
                }

                Section {
                    ForEach(Array(session.log.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.caption2)
                            .monospaced()
                    }
                } header: {
                    Text("Log")
                }
            }
            .navigationTitle("Shared Buys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    var statusText: String {
        switch session.status {
        case .idle: "idle"
        case .connecting: "connecting"
        case .connected: "connected"
        case .offline(let reason): "offline (\(reason))"
        }
    }

    func symbol(for item: SharedBuyItem) -> String {
        switch item.status {
        case .pending: "circle"
        case .bought: "checkmark.circle.fill"
        case .cancelled: "xmark.circle.fill"
        }
    }

    @ViewBuilder
    func qrImage(_ contents: String) -> some View {
        let filter = CIFilter.qrCodeGenerator()
        let context = CIContext()
        if let output = { () -> UIImage? in
            filter.message = Data(contents.utf8)
            guard let image = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 6.0, y: 6.0)),
                  let cgImage = context.createCGImage(image, from: image.extent) else { return nil }
            return UIImage(cgImage: cgImage)
        }() {
            Image(uiImage: output)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 160.0, height: 160.0)
        }
    }
}
