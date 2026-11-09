import SwiftUI

struct PlanHeader: View {

    @Binding var segment: PlanSegment

    var body: some View {
        VStack(spacing: 10.0) {
            HStack(spacing: 8.0) {
                VStack(alignment: .leading, spacing: 0.0) {
                    Text("C107 · 27–28 Dec")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Plan")
                        .font(.title2.weight(.bold))
                }
                Spacer(minLength: 0.0)
                NavigationLink(value: Feature.settings) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .frame(width: 40.0, height: 40.0)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                NavigationLink(value: Feature.myComiket) {
                    ProfileAvatar(size: 40.0)
                }
                .buttonStyle(.plain)
            }
            if segment == .circles || segment == .favorites {
                SearchField()
            }
            GuestBanner()
            Picker("Section", selection: $segment) {
                ForEach(PlanSegment.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 16.0)
        .padding(.top, 16.0)
        .padding(.bottom, 8.0)
    }
}
