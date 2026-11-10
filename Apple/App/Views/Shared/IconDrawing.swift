import SwiftUI
import UIKit

/// Colours and pieces shared by the hand-drawn icons.
enum IconDrawing {

    static func polyline(_ points: [CGPoint]) -> Path {
        var path = Path()
        path.addLines(points)
        return path
    }

    static func drawLine(
        in context: inout GraphicsContext, through points: [CGPoint], color: Color, width: CGFloat
    ) {
        context.stroke(polyline(points), with: .color(color),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    static func drawDot(in context: inout GraphicsContext, at center: CGPoint, radius: CGFloat, color: Color) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2.0, height: radius * 2.0)
        let dot = Path(ellipseIn: rect)
        context.fill(dot, with: .color(color))
        context.stroke(dot, with: .color(outline), lineWidth: radius * 0.45)
    }

    /// A shopping bag filling `rect`: a tall body, with a handle rising out from behind it.
    static func drawBag(in context: inout GraphicsContext, rect: CGRect, body: Color, handle: Color) {
        let outline = rect.width * 0.045
        let band = rect.width * 0.11
        let handleRect = CGRect(x: rect.minX + rect.width * 0.2, y: rect.minY + band / 2.0,
                                width: rect.width * 0.6, height: rect.height * 0.5)
        let handlePath = Path(roundedRect: handleRect, cornerRadius: rect.width * 0.2, style: .continuous)
        context.stroke(handlePath, with: .color(handle), lineWidth: band)
        let bodyRect = CGRect(x: rect.minX + outline / 2.0, y: rect.minY + rect.height * 0.22,
                              width: rect.width - outline, height: rect.height * 0.78 - outline / 2.0)
        let bag = Path(roundedRect: bodyRect, cornerRadius: rect.width * 0.13, style: .continuous)
        fillOutlined(in: &context, bag, in: bodyRect, top: body, bottom: handle, lineWidth: outline)
    }

    /// Fills `path` with a top-to-bottom gradient across `rect`, then outlines it.
    static func fillOutlined(
        in context: inout GraphicsContext, _ path: Path, in rect: CGRect,
        top: Color, bottom: Color, lineWidth: CGFloat
    ) {
        context.fill(path, with: .linearGradient(
            Gradient(colors: [top, bottom]),
            startPoint: CGPoint(x: rect.midX, y: rect.minY),
            endPoint: CGPoint(x: rect.midX, y: rect.maxY)
        ))
        context.stroke(path, with: .color(outline), style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
    }

    static func adaptive(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> Color {
        Color(uiColor: UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1.0)
        })
    }

    static let outline = adaptive(light: (0.0, 0.0, 0.0), dark: (1.0, 1.0, 1.0))
    static let blue = adaptive(light: (0.0, 0.45, 0.93), dark: (0.25, 0.52, 0.98))
    static let deepBlue = adaptive(light: (0.0, 0.3, 0.72), dark: (0.12, 0.36, 0.82))
    static let green = adaptive(light: (0.16, 0.66, 0.29), dark: (0.2, 0.78, 0.35))
    static let deepGreen = adaptive(light: (0.06, 0.48, 0.18), dark: (0.1, 0.58, 0.24))
    static let red = adaptive(light: (0.9, 0.2, 0.2), dark: (0.96, 0.27, 0.27))
    static let deepRed = adaptive(light: (0.68, 0.1, 0.12), dark: (0.76, 0.16, 0.18))
    static let orange = adaptive(light: (0.95, 0.5, 0.15), dark: (1.0, 0.58, 0.29))
    static let deepOrange = adaptive(light: (0.78, 0.36, 0.06), dark: (0.86, 0.42, 0.12))
    static let yellow = adaptive(light: (0.96, 0.8, 0.16), dark: (1.0, 0.86, 0.3))
    static let deepYellow = adaptive(light: (0.8, 0.6, 0.04), dark: (0.86, 0.66, 0.1))
    static let pink = adaptive(light: (0.93, 0.25, 0.5), dark: (0.98, 0.36, 0.6))
    static let deepPink = adaptive(light: (0.7, 0.1, 0.35), dark: (0.78, 0.15, 0.42))
    static let cyan = adaptive(light: (0.0, 0.6, 0.88), dark: (0.0, 0.71, 1.0))
    static let deepCyan = adaptive(light: (0.0, 0.42, 0.68), dark: (0.0, 0.5, 0.78))
    static let purple = adaptive(light: (0.55, 0.3, 0.88), dark: (0.64, 0.4, 0.95))
    static let deepPurple = adaptive(light: (0.38, 0.18, 0.66), dark: (0.45, 0.24, 0.75))
    static let teal = adaptive(light: (0.0, 0.62, 0.58), dark: (0.1, 0.74, 0.7))
    static let deepTeal = adaptive(light: (0.0, 0.44, 0.42), dark: (0.04, 0.52, 0.5))
    static let gray = adaptive(light: (0.62, 0.62, 0.64), dark: (0.6, 0.6, 0.62))
    static let deepGray = adaptive(light: (0.42, 0.42, 0.44), dark: (0.4, 0.4, 0.42))
}
