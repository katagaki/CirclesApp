import SwiftUI

struct TodayHeader: View {

    @Environment(Harness.self) var harness
    @Binding var path: NavigationPath

    var body: some View {
        HStack(spacing: 10.0) {
            VStack(alignment: .leading, spacing: 1.0) {
                Text(harness.day == 1 ? "SAT 27 DEC · DAY 1" : "SUN 28 DEC · DAY 2")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("Today").font(.title2.weight(.bold))
            }
            Spacer(minLength: 8.0)
            NavigationLink(value: TodayDestination.search) {
                Image(systemName: "magnifyingglass")
                    .font(.body.weight(.semibold))
                    .frame(width: 40.0, height: 40.0)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            TodayProfileMenu(path: $path)
        }
        .padding(.horizontal, 16.0)
        .padding(.top, 14.0)
        .padding(.bottom, 6.0)
    }
}
