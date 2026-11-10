import SwiftUI

struct NaviFinishedCard: View {

    @Environment(Navigator.self) var navigator

    var body: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            HStack(alignment: .top, spacing: 12.0) {
                Image(systemName: "flag.checkered")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 48.0, height: 48.0)
                    .background(Color.green.gradient, in: .rect(cornerRadius: 14.0))
                    .frame(width: 56.0, alignment: .leading)
                VStack(alignment: .leading, spacing: 4.0) {
                    Text("Navi.Finished.Title")
                        .font(.headline)
                    Text("Navi.Finished.Message.\(navigator.route?.stops.count ?? 0)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minHeight: 80.0, alignment: .top)
        }
    }
}
