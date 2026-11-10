import SwiftUI

struct MyCircleAppearancePreviewCut: View {

    var palette: [Color]
    var spaceName: String
    var day: Int
    var isVisited: Bool
    var showsColor: Bool
    var showsSpaceName: Bool
    var showsDay: Bool

    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))

            let numberBox = CGRect(x: 0.0, y: 0.0, width: width * 0.22, height: width * 0.22)
            context.stroke(Path(numberBox), with: .color(.black), lineWidth: 0.75)

            let title = CGRect(x: width * 0.3, y: width * 0.06, width: width * 0.6, height: width * 0.1)
            context.fill(Path(roundedRect: title, cornerRadius: 2.0), with: .color(palette[0]))

            let backdrop = CGRect(x: width * 0.1, y: height * 0.26, width: width * 0.8, height: width * 0.8)
            context.fill(Path(ellipseIn: backdrop), with: .color(palette[1].opacity(0.5)))

            let head = CGRect(x: width * 0.33, y: height * 0.32, width: width * 0.34, height: width * 0.34)
            context.fill(Path(ellipseIn: head), with: .color(palette[2]))

            let body = CGRect(
                x: width * 0.24, y: head.maxY + width * 0.04,
                width: width * 0.52, height: height * 0.86 - head.maxY - width * 0.04
            )
            context.fill(Path(roundedRect: body, cornerRadius: width * 0.12), with: .color(palette[0]))

            for line in 0..<2 {
                let bar = CGRect(
                    x: width * 0.12, y: height * 0.9 + CGFloat(line) * height * 0.045,
                    width: width * (line == 0 ? 0.76 : 0.5), height: height * 0.025
                )
                context.fill(Path(bar), with: .color(.black.opacity(0.6)))
            }
        }
        .grayscale(showsColor ? 0.0 : 1.0)
        .aspectRatio(180.0 / 256.0, contentMode: .fit)
        .overlay(alignment: .topLeading) {
            if isVisited {
                GeometryReader { proxy in
                    Image(systemName: "checkmark")
                        .resizable()
                        .scaledToFit()
                        .fontWeight(.black)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: proxy.size.width * 0.2)
                        .padding(proxy.size.width * 0.045)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if showsSpaceName || showsDay {
                VStack(alignment: .trailing, spacing: 2.0) {
                    if showsDay {
                        CircleBlockPill("Shared.\(day)th.Day", size: .tiny)
                    }
                    if showsSpaceName {
                        CircleBlockPill(LocalizedStringKey(spaceName), size: .tiny)
                    }
                }
                .padding(2.0)
            }
        }
    }
}
