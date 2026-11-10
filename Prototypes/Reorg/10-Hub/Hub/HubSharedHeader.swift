import SwiftUI

struct HubSharedHeader: View {

    @Environment(Harness.self) var harness

    var body: some View {
        if harness.isSharedBuysActive {
            NavigationLink(value: Feature.sharedBuys) {
                HStack(spacing: 12.0) {
                    MemberStack(size: 30.0)
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text("Shopping with Aoi and Mika").font(.subheadline.weight(.semibold))
                        Text("\(harness.buys.filter { $0.assignee != nil }.count) items assigned to others · live")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } else {
            Button {
                withAnimation { harness.isSharedBuysActive = true }
            } label: {
                HStack(spacing: 12.0) {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.purple)
                        .frame(width: 30.0)
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text("Shop together").font(.subheadline.weight(.semibold))
                        Text("Share this list and split up the circles").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0.0)
                    Image(systemName: "plus.circle.fill").foregroundStyle(.purple)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }
}
