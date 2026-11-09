import SwiftUI

struct ToolbeltDayHallMenu: View {

    @Environment(Harness.self) var harness

    var hallNumber: String {
        harness.hall.name.split(separator: " ").last.map(String.init) ?? ""
    }

    var body: some View {
        @Bindable var harness = harness
        Menu {
            Picker("Day", selection: $harness.day) {
                Text("Day 1 · Sat 27 Dec").tag(1)
                Text("Day 2 · Sun 28 Dec").tag(2)
            }
            Picker("Hall", selection: $harness.hall) {
                ForEach(Hall.allCases) { hall in
                    Text(hall.name).tag(hall)
                }
            }
        } label: {
            VStack(spacing: 2.0) {
                Text("DAY \(harness.day)")
                    .font(.system(size: 9.0, weight: .heavy))
                    .foregroundStyle(.secondary)
                Text("\(harness.hall.shortName)\(hallNumber)")
                    .font(.system(size: 12.0, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4.0)
                    .frame(height: 20.0)
                    .background(harness.hall.accent, in: .capsule)
            }
            .frame(width: 48.0, height: 52.0)
            .contentShape(.rect)
        }
        .accessibilityLabel("Day \(harness.day), \(harness.hall.name)")
    }
}
