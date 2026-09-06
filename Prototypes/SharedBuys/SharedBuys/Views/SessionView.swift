//
//  SessionView.swift
//  SharedBuys
//

import SwiftUI

struct SessionView: View {

    @Environment(Mesh.self) var mesh
    @Environment(\.dismiss) var dismiss

    var device: DeviceNode { mesh.focused }

    var pairingURL: String {
        "circles://buys/join?s=Yk8xQ2xMd1E&k=8fT2pQr7Kz1&n=1001"
    }

    var body: some View {
        NavigationStack {
        List {
            if device.isSessionActive {
                Section {
                    VStack(spacing: 12.0) {
                        QRCodeView(contents: pairingURL)
                        Text("Scan this code to join the shared list")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("CIRCLES-4K7Q")
                            .font(.title3)
                            .fontWeight(.bold)
                            .monospaced()
                            .kerning(2.0)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8.0)
                    .listRowBackground(Color.clear)
                }
                Section {
                    ForEach(mesh.activeDevices) { peer in
                        HStack(spacing: 10.0) {
                            MemberAvatar(member: peer.member, size: 30.0)
                            Text(peer.member.nickname)
                            Spacer()
                        }
                    }
                } header: {
                    Text("Members")
                }
            } else {
                Section {
                    Button {
                        mesh.join(device)
                    } label: {
                        Label("Scan QR to join", systemImage: "qrcode.viewfinder")
                    }
                } footer: {
                    Text("Joining starts the session on this device and shows its Live Activity.")
                }
            }

            if device.isSessionActive {
                Section {
                    Button("End session on this device", role: .destructive) {
                        mesh.leave(device)
                    }
                }
            }
        }
        .navigationTitle("Shared list")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) { dismiss() }
            }
        }
        }
    }
}
