//
//  HallMinimap.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/09/02.
//

import SwiftUI
import AXiS

struct HallMinimap: View {

    let maps: [ComiketMap]
    let selection: ComiketMap?
    var width: CGFloat = 268.0
    let onSelect: (ComiketMap) -> Void

    @State var pressedMapID: Int?

    static let east78Shape: [CGPoint] = [
        CGPoint(x: 29.5, y: 41.5), CGPoint(x: 36.5, y: 41.5),
        CGPoint(x: 32.5, y: 55.0), CGPoint(x: 32.5, y: 69.0),
        CGPoint(x: 19.0, y: 69.0)
    ]
    static let east123Frame = CGRect(x: 47.0, y: 41.5, width: 29.0, height: 12.0)
    static let east456Frame = CGRect(x: 36.5, y: 57.0, width: 29.0, height: 12.0)
    static let westFrame = CGRect(x: 80.0, y: 12.5, width: 29.0, height: 25.0)
    static let southFrame = CGRect(x: 91.0, y: -16.5, width: 18.0, height: 25.0)
    static let conferenceFrame = CGRect(x: 80.0, y: 41.5, width: 29.0, height: 27.5)

    static let floorGap: CGFloat = 1.0
    static let labelFontSize: CGFloat = 16.0
    static let disabledOpacity: CGFloat = 0.3

    static let conferenceColor = Color(red: 0.55, green: 0.49, blue: 0.42)

    static func rectangle(_ rect: CGRect) -> [CGPoint] {
        [
            CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY)
        ]
    }

    static func upperFloor(of rect: CGRect) -> CGRect {
        CGRect(x: rect.minX, y: rect.minY,
               width: rect.width, height: rect.height / 2.0 - floorGap / 2.0)
    }

    static func lowerFloor(of rect: CGRect) -> CGRect {
        CGRect(x: rect.minX, y: rect.midY + floorGap / 2.0,
               width: rect.width, height: rect.height / 2.0 - floorGap / 2.0)
    }

    static func bounds(of shape: [CGPoint]) -> CGRect {
        let xValues = shape.map { $0.x }
        let yValues = shape.map { $0.y }
        guard let minX = xValues.min(), let maxX = xValues.max(),
              let minY = yValues.min(), let maxY = yValues.max() else { return .zero }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    static func isRectangular(_ shape: [CGPoint]) -> Bool {
        let bounds = bounds(of: shape)
        return shape.count == 4 && shape.allSatisfy {
            ($0.x == bounds.minX || $0.x == bounds.maxX) && ($0.y == bounds.minY || $0.y == bounds.maxY)
        }
    }

    static func horizontalSpan(of shape: [CGPoint], at positionY: CGFloat) -> ClosedRange<CGFloat>? {
        var crossings: [CGFloat] = []
        for index in shape.indices {
            let start = shape[index]
            let end = shape[(index + 1) % shape.count]
            guard min(start.y, end.y) <= positionY, positionY <= max(start.y, end.y),
                  start.y != end.y else { continue }
            let ratio = (positionY - start.y) / (end.y - start.y)
            crossings.append(start.x + (end.x - start.x) * ratio)
        }
        guard let minimumX = crossings.min(), let maximumX = crossings.max(),
              minimumX < maximumX else { return nil }
        return minimumX...maximumX
    }

    // Keeps the caption inside angled halls, where the bounding box is wider than the hall itself.
    static func labelFrame(of shape: [CGPoint]) -> CGRect {
        let bounds = bounds(of: shape)
        guard !isRectangular(shape) else { return bounds }
        var widest: ClosedRange<CGFloat>?
        var widestY = bounds.midY
        for step in stride(from: 0.35, through: 0.8, by: 0.05) {
            let positionY = bounds.minY + bounds.height * step
            guard let span = horizontalSpan(of: shape, at: positionY) else { continue }
            if span.upperBound - span.lowerBound > (widest.map { $0.upperBound - $0.lowerBound } ?? 0.0) {
                widest = span
                widestY = positionY
            }
        }
        guard let widest else { return bounds }
        let height = bounds.height * 0.5
        return CGRect(x: widest.lowerBound, y: widestY - height / 2.0,
                      width: widest.upperBound - widest.lowerBound, height: height)
    }

    static func path(of shape: [CGPoint]) -> Path {
        if isRectangular(shape) {
            return Path(bounds(of: shape))
        }
        var path = Path()
        path.addLines(shape)
        path.closeSubpath()
        return path
    }

    static func color(for filename: String) -> Color {
        switch filename.first {
        case "E": return Color(red: 0.90, green: 0.25, blue: 0.21)
        case "W": return Color(red: 0.20, green: 0.51, blue: 0.93)
        case "S": return Color(red: 0.18, green: 0.68, blue: 0.40)
        default: return conferenceColor
        }
    }

    // Every hall the venue has, so halls the event does not use can still be shown as disabled.
    static let slots: [HallSlot] = [
        HallSlot(filenames: ["E78", "E7"], shape: east78Shape, placeholderName: "東78"),
        HallSlot(filenames: ["E123"], shape: rectangle(east123Frame), placeholderName: "東123"),
        HallSlot(filenames: ["E456"], shape: rectangle(east456Frame), placeholderName: "東456"),
        HallSlot(filenames: ["W34"], shape: rectangle(upperFloor(of: westFrame)), placeholderName: "西34"),
        HallSlot(filenames: ["W12"], shape: rectangle(lowerFloor(of: westFrame)), placeholderName: "西12"),
        HallSlot(filenames: ["S34"], shape: rectangle(upperFloor(of: southFrame)), placeholderName: "南34"),
        HallSlot(filenames: ["S12"], shape: rectangle(lowerFloor(of: southFrame)), placeholderName: "南12")
    ]

    static let contentFrame: CGRect = {
        var bounds = conferenceFrame
        for slot in slots {
            bounds = bounds.union(HallMinimap.bounds(of: slot.shape))
        }
        return bounds.insetBy(dx: -2.0, dy: -2.0)
    }()

    var halls: [(slot: HallSlot, map: ComiketMap?)] {
        Self.slots.map { slot in
            (slot, maps.first(where: { slot.filenames.contains($0.filename) }))
        }
    }

    var unplacedMaps: [ComiketMap] {
        let placedIDs = Set(halls.compactMap { $0.map?.id })
        return maps.filter { !placedIDs.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 12.0) {
            minimap()
            if !unplacedMaps.isEmpty {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8.0) { unplacedMapButtons() }
                    VStack(spacing: 8.0) { unplacedMapButtons() }
                }
            }
        }
    }

    func minimap() -> some View {
        let contentFrame = Self.contentFrame
        let scale = width / contentFrame.width
        return ZStack {
            Canvas { context, _ in
                draw(in: context, scale: scale)
            }
            ForEach(halls, id: \.slot.id) { hall in
                if let map = hall.map {
                    let frame = Self.bounds(of: hall.slot.shape)
                    Button {
                        onSelect(map)
                    } label: {
                        Color.clear
                            .contentShape(HallShape(points: hall.slot.shape, bounds: frame))
                    }
                    .buttonStyle(HallButtonStyle { isPressed in
                        pressedMapID = isPressed ? map.id : nil
                    })
                    .frame(width: frame.width * scale, height: frame.height * scale)
                    .position(x: (frame.midX - contentFrame.minX) * scale,
                              y: (frame.midY - contentFrame.minY) * scale)
                    .accessibilityLabel(map.name)
                    .accessibilityAddTraits(map == selection ? [.isSelected] : [])
                }
            }
        }
        .frame(width: width, height: contentFrame.height * scale)
    }

    @ViewBuilder
    func unplacedMapButtons() -> some View {
        ForEach(unplacedMaps, id: \.id) { map in
            Button {
                onSelect(map)
            } label: {
                Text(map.name)
                    .font(.caption)
                    .bold()
                    .padding(.vertical, 6.0)
                    .padding(.horizontal, 12.0)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(map == selection ? .white : Self.color(for: map.filename))
                    .background(Self.color(for: map.filename).opacity(map == selection ? 1.0 : 0.2))
                    .clipShape(.capsule)
            }
            .buttonStyle(.plain)
        }
    }

    func draw(in context: GraphicsContext, scale: CGFloat) {
        var context = context
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -Self.contentFrame.minX, y: -Self.contentFrame.minY)

        context.fill(
            Path(Self.conferenceFrame),
            with: .color(Self.conferenceColor.opacity(Self.disabledOpacity))
        )
        drawLabel(
            Text("Shared.Building.Conference"),
            in: Self.conferenceFrame,
            color: .white.opacity(Self.disabledOpacity),
            context: context,
            scale: scale
        )

        for hall in halls {
            draw(hall, in: context, scale: scale)
        }
    }

    func draw(
        _ hall: (slot: HallSlot, map: ComiketMap?),
        in context: GraphicsContext,
        scale: CGFloat
    ) {
        let color = Self.color(for: hall.slot.id)
        let path = Self.path(of: hall.slot.shape)
        context.fill(path, with: .color(color.opacity(hall.map == nil ? Self.disabledOpacity : 1.0)))
        if let map = hall.map {
            if map.id == pressedMapID {
                context.fill(path, with: .color(.black.opacity(0.25)))
            }
            if map == selection {
                context.stroke(path, with: .color(.white), lineWidth: 1.5 / scale)
            }
        }
        drawLabel(
            Text(hall.map?.name ?? hall.slot.placeholderName),
            in: Self.labelFrame(of: hall.slot.shape),
            color: hall.map == nil ? .white.opacity(Self.disabledOpacity) : .white,
            context: context,
            scale: scale
        )
    }

    func drawLabel(
        _ text: Text,
        in frame: CGRect,
        color: Color,
        context: GraphicsContext,
        scale: CGFloat
    ) {
        func resolve(_ fontSize: CGFloat) -> GraphicsContext.ResolvedText {
            context.resolve(
                text
                    .font(.system(size: fontSize / scale, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            )
        }
        var resolved = resolve(Self.labelFontSize)
        let size = resolved.measure(in: CGSize(width: CGFloat.infinity, height: CGFloat.infinity))
        let maximumWidth = frame.width * 0.85
        let maximumHeight = frame.height * 0.8
        let factor = min(maximumWidth / size.width, maximumHeight / size.height, 1.0)
        if factor < 1.0 {
            resolved = resolve(Self.labelFontSize * factor)
        }
        context.draw(resolved, at: CGPoint(x: frame.midX, y: frame.midY))
    }
}

struct HallSlot: Identifiable {

    let filenames: [String]
    let shape: [CGPoint]
    let placeholderName: String

    var id: String { filenames[0] }
}

struct HallButtonStyle: ButtonStyle {

    let onPressChange: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, isPressed in
                onPressChange(isPressed)
            }
    }
}

struct HallShape: Shape {

    let points: [CGPoint]
    let bounds: CGRect

    func path(in rect: CGRect) -> Path {
        guard bounds.width > 0.0, bounds.height > 0.0 else { return Path(rect) }
        let scaleX = rect.width / bounds.width
        let scaleY = rect.height / bounds.height
        var path = Path()
        path.addLines(points.map {
            CGPoint(x: rect.minX + ($0.x - bounds.minX) * scaleX,
                    y: rect.minY + ($0.y - bounds.minY) * scaleY)
        })
        path.closeSubpath()
        return path
    }
}
