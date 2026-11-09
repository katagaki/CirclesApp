import SwiftUI

struct MyComiketView: View {

    @Environment(Harness.self) var harness
    @State var days: [Int: Bool] = [1: true, 2: false]

    var body: some View {
        List {
            Section {
                ProfileHeader()
                    .listRowBackground(Color.clear)
            }
            if harness.isGuest {
                Section {
                    GuestBanner().listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                }
            } else {
                Section("Participation · C107") {
                    ForEach([1, 2], id: \.self) { day in
                        Toggle(isOn: Binding(get: { days[day] ?? false }, set: { days[day] = $0 })) {
                            VStack(alignment: .leading) {
                                Text("Day \(day)")
                                Text(day == 1 ? "Sat 27 Dec · East/West" : "Sun 28 Dec · South").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section {
                    Label("Event Reminders", systemImage: "bell.badge")
                    Label("Circle.ms Profile", systemImage: "safari")
                }
            }
        }
        .navigationTitle("My Comiket")
    }
}
