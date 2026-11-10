import SwiftUI

struct ListIconImage: View {

    let name: String
    var size: CGFloat = 30.0

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(Color.primary.opacity(0.1), lineWidth: 1.0)
            }
    }
}
