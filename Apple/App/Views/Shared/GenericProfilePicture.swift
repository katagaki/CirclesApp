import SwiftUI

/// The picture shown when no profile photo is set: a figure carrying a backpack.
///
/// The figure and background take their hue from the circle.ms name and the backpack
/// from the user ID, so two people sharing a name still carry different backpacks.
/// Both hashes are stable across launches and devices, unlike `hashValue`.
struct GenericProfilePicture: View {

    @Environment(\.colorScheme) var colorScheme

    let name: String
    let userID: Int

    var figureHue: Double? {
        guard !name.isEmpty else { return nil }
        var hash: UInt32 = 2_166_136_261
        for unit in name.utf16 { hash = (hash ^ UInt32(unit)) &* 16_777_619 }
        hash ^= hash >> 16
        hash = hash &* 0x7FEB_352D
        hash ^= hash >> 15
        return Double(hash % 360) / 360.0
    }

    static let backpacks: [(red: Double, green: Double, blue: Double)] = [
        (0.55, 0.38, 0.24),
        (0.42, 0.27, 0.18),
        (0.66, 0.50, 0.34),
        (0.36, 0.42, 0.48),
        (0.27, 0.31, 0.36),
        (0.33, 0.37, 0.22),
        (0.42, 0.45, 0.29),
        (0.45, 0.45, 0.44)
    ]

    var backpack: (red: Double, green: Double, blue: Double) {
        guard userID != 0 else { return (0.42, 0.42, 0.42) }
        var hash = UInt32(truncatingIfNeeded: userID.magnitude)
        hash ^= hash >> 16
        hash = hash &* 0x7FEB_352D
        hash ^= hash >> 15
        hash = hash &* 0x846C_A68B
        hash ^= hash >> 16
        return Self.backpacks[Int(hash % UInt32(Self.backpacks.count))]
    }

    func backpack(scaledBy factor: Double) -> Color {
        let base = backpack
        return Color(red: min(base.red * factor, 1.0),
                     green: min(base.green * factor, 1.0),
                     blue: min(base.blue * factor, 1.0))
    }

    var isDark: Bool { colorScheme == .dark }

    var backgroundTop: Color {
        guard let figureHue else {
            return isDark ? Color(white: 0.24) : Color(white: 0.93)
        }
        return isDark
            ? Color(hue: figureHue, saturation: 0.35, brightness: 0.30)
            : Color(hue: figureHue, saturation: 0.10, brightness: 0.98)
    }

    var backgroundBottom: Color {
        guard let figureHue else {
            return isDark ? Color(white: 0.16) : Color(white: 0.84)
        }
        return isDark
            ? Color(hue: figureHue, saturation: 0.45, brightness: 0.20)
            : Color(hue: figureHue, saturation: 0.24, brightness: 0.90)
    }

    var figureLight: Color {
        guard let figureHue else { return Color(white: 0.68) }
        return Color(hue: figureHue, saturation: 0.50, brightness: 0.92)
    }

    var figureDark: Color {
        guard let figureHue else { return Color(white: 0.56) }
        return Color(hue: figureHue, saturation: 0.68, brightness: 0.80)
    }

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let origin = CGPoint(x: (size.width - side) / 2.0, y: (size.height - side) / 2.0)
            func rect(_ x: Double, _ y: Double, _ width: Double, _ height: Double) -> CGRect {
                CGRect(x: origin.x + x * side, y: origin.y + y * side,
                       width: width * side, height: height * side)
            }
            func point(_ x: Double, _ y: Double) -> CGPoint {
                CGPoint(x: origin.x + x * side, y: origin.y + y * side)
            }

            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(Gradient(colors: [backgroundTop, backgroundBottom]),
                                      startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
            )

            let pack = Path(roundedRect: rect(0.24, 0.53, 0.52, 0.50), cornerRadius: 0.10 * side)
            context.fill(pack, with: .linearGradient(
                Gradient(colors: [backpack(scaledBy: 1.25), backpack(scaledBy: 1.0), backpack(scaledBy: 0.75)]),
                startPoint: point(0.5, 0.53), endPoint: point(0.5, 0.74)
            ))

            let figureShading = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [figureLight, figureDark]),
                startPoint: point(0.25, 0.2), endPoint: point(0.75, 1.0)
            )
            let torso = Path(roundedRect: rect(0.14, 0.65, 0.72, 0.60), cornerRadius: 0.24 * side)
            context.fill(torso, with: figureShading)

            var straps = context
            straps.clip(to: torso)
            let strapShading = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [backpack(scaledBy: 1.15), backpack(scaledBy: 0.8)]),
                startPoint: point(0.5, 0.65), endPoint: point(0.5, 1.0)
            )
            straps.fill(Path(roundedRect: rect(0.30, 0.60, 0.075, 0.50), cornerRadius: 0.0375 * side),
                        with: strapShading)
            straps.fill(Path(roundedRect: rect(0.625, 0.60, 0.075, 0.50), cornerRadius: 0.0375 * side),
                        with: strapShading)

            context.fill(Path(ellipseIn: rect(0.31, 0.19, 0.38, 0.38)), with: figureShading)
        }
        .accessibilityHidden(true)
    }
}
