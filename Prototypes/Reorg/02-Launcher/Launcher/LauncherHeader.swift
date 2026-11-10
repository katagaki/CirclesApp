import SwiftUI

struct LauncherHeader: View {

    var body: some View {
        HStack(spacing: 10.0) {
            SearchField()
            NavigationLink(value: Feature.myComiket) {
                ProfileAvatar(size: 40.0)
            }
            .buttonStyle(.plain)
        }
    }
}
