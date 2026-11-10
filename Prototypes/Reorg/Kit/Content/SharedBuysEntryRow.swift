import SwiftUI

struct SharedBuysEntryRow: View {

    @Environment(Harness.self) var harness

    var body: some View {
        if harness.isSharedBuysActive {
            NavigationLink(value: Feature.sharedBuys) {
                HStack(spacing: 12.0) {
                    MemberStack()
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text("Shared with Aoi and Mika").font(.subheadline.weight(.semibold))
                        Text("3 items assigned to others").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        } else {
            Button {
                harness.isSharedBuysActive = true
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text("Shop together").font(.subheadline.weight(.semibold))
                        Text("Share this list and split up the circles").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "person.2.fill").foregroundStyle(.purple)
                }
            }
            .buttonStyle(.plain)
        }
    }
}
