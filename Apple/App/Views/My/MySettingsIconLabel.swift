import SwiftUI

struct MySettingsIconLabel: View {

    let title: LocalizedStringKey
    let systemImage: String
    let color: Color
    var iconSize: CGFloat = 30.0

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .frame(width: iconSize * 0.6, height: iconSize * 0.6)
                .frame(width: iconSize, height: iconSize)
                .background(color.gradient, in: .rect(cornerRadius: iconSize * 0.27, style: .continuous))
        }
    }
}
