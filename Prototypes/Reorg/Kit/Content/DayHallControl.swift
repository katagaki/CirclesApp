import SwiftUI

struct DayHallControl: View {

    @Environment(Harness.self) var harness

    var body: some View {
        @Bindable var harness = harness
        HStack(spacing: 4.0) {
            Menu {
                Picker("Day", selection: $harness.day) {
                    Text("Day 1 · Sat 27 Dec").tag(1)
                    Text("Day 2 · Sun 28 Dec").tag(2)
                }
            } label: {
                Text("Day \(harness.day)")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12.0)
                    .frame(height: 32.0)
            }
            Menu {
                Picker("Hall", selection: $harness.hall) {
                    ForEach(Hall.allCases) { hall in
                        Text(hall.name).tag(hall)
                    }
                }
            } label: {
                Text(harness.hall.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12.0)
                    .frame(height: 32.0)
                    .background(harness.hall.accent, in: .capsule)
            }
        }
        .foregroundStyle(.primary)
        .padding(4.0)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}
