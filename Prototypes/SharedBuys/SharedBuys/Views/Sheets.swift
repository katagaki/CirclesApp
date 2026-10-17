import SwiftUI

struct AddItemSheet: View {

    @Environment(Mesh.self) var mesh
    @Environment(\.dismiss) var dismiss

    @State var name: String = ""
    @State var cost: String = ""
    @State var circleID: Int = SampleData.circles[0].id
    @State var assignToSelf: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Item name", text: $name)
                    TextField("Cost", text: $cost)
                        .keyboardType(.numberPad)
                    Picker("Circle", selection: $circleID) {
                        ForEach(SampleData.circles) { circle in
                            Text(circle.name).tag(circle.id)
                        }
                    }
                }
                Section {
                    Toggle("Assign to me", isOn: $assignToSelf)
                } footer: {
                    Text("Everyone in the session sees this item the moment it syncs.")
                }
            }
            .navigationTitle("New shared item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let device = mesh.focused
                        let itemID = UUID().uuidString.prefix(8).lowercased()
                        device.makeOp(
                            .addItem,
                            itemID: String(itemID),
                            circleID: circleID,
                            text: name,
                            value: Int(cost) ?? 0
                        )
                        if assignToSelf {
                            device.makeOp(
                                .setAssignee,
                                itemID: String(itemID),
                                circleID: circleID,
                                value: device.member.id
                            )
                        }
                        mesh.converge()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct AssignSheet: View {

    @Environment(Mesh.self) var mesh
    @Environment(\.dismiss) var dismiss
    let item: SharedItem

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(mesh.activeDevices) { device in
                        Button {
                            assign(to: device.member.id)
                        } label: {
                            HStack(spacing: 10.0) {
                                MemberAvatar(member: device.member, size: 28.0)
                                Text(device.member.nickname)
                                Spacer()
                                if item.assignee == device.member.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Who is buying this?")
                }
                Section {
                    Button("Leave unassigned", role: .destructive) {
                        assign(to: nil)
                    }
                }
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    func assign(to pid: Int?) {
        mesh.focused.makeOp(.setAssignee, itemID: item.id, circleID: item.circleID, value: pid)
        mesh.converge()
        dismiss()
    }
}
