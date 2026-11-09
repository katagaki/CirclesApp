import SwiftUI

public struct MemberInitial: View {

    let nickname: String
    var isMine: Bool = false
    var size: CGFloat = 26.0

    public init(nickname: String, isMine: Bool = false, size: CGFloat = 26.0) {
        self.nickname = nickname
        self.isMine = isMine
        self.size = size
    }

    public var body: some View {
        Circle()
            .fill(color.gradient)
            .frame(width: size, height: size)
            .overlay {
                Text(String(nickname.prefix(1)))
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay {
                Circle().strokeBorder(isMine ? Color.accentColor : .clear, lineWidth: 2.0)
            }
    }

    var color: Color {
        let palette: [Color] = [.orange, .teal, .purple, .pink, .indigo, .green]
        return palette[SharedBuysPalette.index(for: nickname, count: palette.count)]
    }
}
