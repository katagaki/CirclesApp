//
//  HarnessChrome.swift
//  SharedBuys
//
//  Prototype scaffolding. Nothing in this file is proposed app UI.
//

import SwiftUI

struct HarnessBar: View {

    @Environment(Mesh.self) var mesh
    @Binding var isShowingHarness: Bool

    var body: some View {
        HStack(spacing: 4.0) {
            Text("HARNESS")
                .font(.system(size: 9.0, weight: .heavy))
                .monospaced()
                .foregroundStyle(.white.opacity(0.4))
                .padding(.trailing, 4.0)
            ForEach(mesh.devices) { device in
                Button {
                    withAnimation(.smooth.speed(2.0)) {
                        mesh.focusedDeviceID = device.id
                    }
                } label: {
                    HStack(spacing: 5.0) {
                        MemberAvatar(member: device.member, size: 20.0)
                            .opacity(device.isSessionActive ? 1.0 : 0.3)
                        if device.id == mesh.focusedDeviceID {
                            Text(device.member.nickname)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, 6.0)
                    .padding(.vertical, 4.0)
                    .background(
                        device.id == mesh.focusedDeviceID ? Color.white.opacity(0.18) : .clear,
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0.0)
            Button {
                withAnimation(.smooth.speed(2.0)) { mesh.isJapanese.toggle() }
            } label: {
                Text(mesh.isJapanese ? "JA" : "EN")
                    .font(.system(size: 10.0, weight: .heavy))
                    .monospaced()
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 6.0)
                    .padding(.vertical, 4.0)
                    .background(Color.white.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
            Button {
                isShowingHarness = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(6.0)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10.0)
        .padding(.vertical, 4.0)
        .background(Color.black.opacity(0.75), in: Capsule())
        .padding(.horizontal, 16.0)
        .padding(.top, 4.0)
    }
}

struct HarnessSheet: View {

    @Environment(Mesh.self) var mesh
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(mesh.devices) { node in
                        DeviceRadioControls(device: node)
                    }
                } header: {
                    Text("Simulated radios")
                } footer: {
                    Text("Turn a device's Bluetooth off or walk it out of range to watch the mesh fall "
                         + "back to the internet relay, and then to a local queue when both are gone.")
                }

                Section {
                    LabeledContent("Version vector", value: describe(mesh.focused.versionVector))
                    LabeledContent("Advertised digest", value: mesh.focused.versionVector.digest)
                    LabeledContent("Ops held", value: "\(mesh.focused.ops.count)")
                } header: {
                    Text("\(mesh.focused.member.nickname)'s replica")
                }

                Section {
                    LabeledContent("Over Bluetooth", value: "\(mesh.totalBluetoothBytes) B")
                    LabeledContent("Over internet", value: "\(mesh.totalInternetBytes) B")
                    LabeledContent("Syncs skipped by digest", value: "\(mesh.totalSkipped)")
                } header: {
                    Text("Traffic since launch")
                } footer: {
                    Text("A skipped sync is a radio wake-up that never happened: the peer's advertised "
                         + "state digest already matched what we had.")
                }

                Section {
                    if mesh.wireLog.isEmpty {
                        Text("Nothing sent yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(mesh.wireLog) { event in
                            HStack(spacing: 10.0) {
                                Image(systemName: event.channel.symbolName)
                                    .foregroundStyle(event.channel == .bluetooth ? .blue : .green)
                                    .frame(width: 22.0)
                                VStack(alignment: .leading, spacing: 1.0) {
                                    Text("\(event.from) → \(event.to)  \(event.summary)")
                                        .font(.caption)
                                        .monospaced()
                                    Text(event.at, style: .time)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                Spacer()
                                Text("\(event.bytes) B")
                                    .font(.caption2)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Bytes on the wire")
                } footer: {
                    Text("Only the ops a peer is missing ever cross a radio. A full list is never resent.")
                }
            }
            .navigationTitle("Harness")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    func describe(_ vector: VersionVector) -> String {
        vector.keys.sorted().map { "\($0):\(vector[$0] ?? 0)" }.joined(separator: " ")
    }
}

struct DeviceRadioControls: View {

    @Environment(Mesh.self) var mesh
    @Bindable var device: DeviceNode

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            HStack(spacing: 8.0) {
                MemberAvatar(member: device.member, size: 22.0)
                Text(device.member.nickname)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if !device.isSessionActive {
                    Text("not in session")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            HStack(spacing: 6.0) {
                RadioToggle(title: "BT", systemImage: "dot.radiowaves.left.and.right",
                            isOn: $device.isBluetoothEnabled, tint: .blue)
                RadioToggle(title: "Near", systemImage: "figure.walk",
                            isOn: $device.isNearby, tint: .indigo)
                RadioToggle(title: "Net", systemImage: "network",
                            isOn: $device.hasInternet, tint: .green)
            }
        }
        .padding(.vertical, 2.0)
    }
}

struct RadioToggle: View {

    let title: String
    let systemImage: String
    @Binding var isOn: Bool
    let tint: Color

    var body: some View {
        Button {
            withAnimation(.smooth.speed(2.0)) { isOn.toggle() }
        } label: {
            HStack(spacing: 4.0) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10.0)
            .padding(.vertical, 6.0)
            .frame(maxWidth: .infinity)
            .background(isOn ? tint.opacity(0.16) : Color(.tertiarySystemFill), in: Capsule())
            .foregroundStyle(isOn ? tint : Color.secondary)
        }
        .buttonStyle(.plain)
    }
}
