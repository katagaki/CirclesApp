//
//  SharedBuysSheet.swift
//  CiRCLES
//

import CoreImage.CIFilterBuiltins
import ORBiT
import SwiftUI

struct SharedBuysSheet: View {

    @Environment(SharedBuysSession.self) var sharedBuys
    @Environment(Events.self) var planner
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                if sharedBuys.isActive {
                    Section {
                        VStack(spacing: 12.0) {
                            if let joinURL = sharedBuys.joinURL {
                                JoinCodeImage(contents: joinURL.absoluteString)
                            }
                            Text("Buys.Shared.ScanToJoin")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8.0)
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        ForEach(sharedBuys.members.sorted(by: { $0.value < $1.value }), id: \.key) { member in
                            HStack(spacing: 10.0) {
                                MemberInitial(
                                    nickname: member.value,
                                    isMine: member.key == sharedBuys.actorPID,
                                    size: 30.0
                                )
                                Text(member.value)
                            }
                        }
                    } header: {
                        Text("Buys.Shared.Members")
                    }

                    Section {
                        Button("Buys.Shared.End", role: .destructive) {
                            sharedBuys.leave()
                            dismiss()
                        }
                    }
                } else {
                    Section {
                        Button {
                            sharedBuys.start(
                                eventNumber: planner.activeEventNumber,
                                nickname: sharedBuys.nickname
                            )
                        } label: {
                            Label("Buys.Shared.Start", systemImage: "person.2.badge.plus")
                        }
                    } footer: {
                        Text("Buys.Shared.Explain")
                    }
                }
            }
            .navigationTitle("Buys.Shared.Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) { dismiss() }
                }
            }
        }
    }
}

struct JoinCodeImage: View {

    let contents: String
    var size: CGFloat = 200.0

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 8.0)
                    .fill(Color(.systemGray5))
            }
        }
        .frame(width: size, height: size)
        .padding(12.0)
        .background(.white, in: RoundedRectangle(cornerRadius: 16.0))
    }

    var image: UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(contents.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10.0, y: 10.0))
        guard let cgImage = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct SharedBuyAssignSheet: View {

    @Environment(SharedBuysSession.self) var sharedBuys
    @Environment(\.dismiss) var dismiss
    let item: SharedBuyItem

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(sharedBuys.members.sorted(by: { $0.value < $1.value }), id: \.key) { member in
                        Button {
                            sharedBuys.assign(item, to: member.key)
                            dismiss()
                        } label: {
                            HStack(spacing: 10.0) {
                                MemberInitial(nickname: member.value, size: 28.0)
                                Text(member.value)
                                Spacer()
                                if item.assignee == member.key {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Buys.Shared.Assign")
                }
                Section {
                    Button("Buys.Shared.Unassign", role: .destructive) {
                        sharedBuys.assign(item, to: nil)
                        dismiss()
                    }
                }
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

struct SharedBuyAddSheet: View {

    @Environment(SharedBuysSession.self) var sharedBuys
    @Environment(\.dismiss) var dismiss

    let circleID: Int

    @State private var name: String = ""
    @State private var cost: String = ""
    @FocusState private var isNameFocused: Bool

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Buys.ItemName.Placeholder", text: $name)
                        .focused($isNameFocused)
                    TextField("Buys.ItemCost.Placeholder", text: $cost)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Buys.AddItem.Shared")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        sharedBuys.addItem(
                            name: trimmedName,
                            cost: Int(cost) ?? 0,
                            circleID: circleID
                        )
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear {
                isNameFocused = true
            }
        }
        .presentationDetents([.medium])
    }
}
