import SwiftUI

struct SharedBuysView: View {

    @Environment(Harness.self) var harness

    var body: some View {
        List {
            if harness.isSharedBuysActive {
                Section("Members") {
                    ForEach(MockData.members) { member in
                        SharedMemberRow(member: member)
                    }
                }
                Section("Assigned to others") {
                    ForEach(harness.buys.filter { $0.assignee != nil }) { item in
                        BuyRow(item: item)
                    }
                }
                Section {
                    Button("Invite Someone", systemImage: "qrcode") {}
                    Button("Leave Shared List", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                        harness.isSharedBuysActive = false
                    }
                }
            } else {
                Section {
                    SharedBuysOnboarding()
                        .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Shared Buys")
    }
}
