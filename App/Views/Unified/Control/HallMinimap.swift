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

    static let east78Shape: [CGPoint] = [
        CGPoint(x: 25.5, y: 41.5), CGPoint(x: 32.5, y: 41.5),
        CGPoint(x: 28.5, y: 55.0), CGPoint(x: 28.5, y: 69.0),
        CGPoint(x: 15.0, y: 69.0)
    ]
    static let east123Frame = CGRect(x: 43.5, y: 41.5, width: 29.0, height: 10.5)
    static let east456Frame = CGRect(x: 33.0, y: 57.5, width: 29.0, height: 10.5)
    static let westFrame = CGRect(x: 77.0, y: 24.0, width: 27.0, height: 14.0)
    static let southFrame = CGRect(x: 91.0, y: 4.0, width: 13.0, height: 18.0)
    static let conferenceFrame = CGRect(x: 77.0, y: 41.5, width: 27.0, height: 27.5)

    static let floorGap: CGFloat = 1.0
    static let labelFontSize: CGFloat = 12.0

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

    func shape(for map: ComiketMap) -> [CGPoint]? {
        let filenames = maps.map { $0.filename }
        switch map.filename {
        case "E7", "E78": return Self.east78Shape
        case "E123": return Self.rectangle(Self.east123Frame)
        case "E456": return Self.rectangle(Self.east456Frame)
        case "W34":
            return Self.rectangle(
                filenames.contains("W12") ? Self.upperFloor(of: Self.westFrame) : Self.westFrame
            )
        case "W12":
            return Self.rectangle(
                filenames.contains("W34") ? Self.lowerFloor(of: Self.westFrame) : Self.westFrame
            )
        case "S34":
            return Self.rectangle(
                filenames.contains("S12") ? Self.upperFloor(of: Self.southFrame) : Self.southFrame
            )
        case "S12":
            return Self.rectangle(
                filenames.contains("S34") ? Self.lowerFloor(of: Self.southFrame) : Self.southFrame
            )
        default:
            return map.filename.hasPrefix("C") ? Self.rectangle(Self.conferenceFrame) : nil
        }
    }

    var placedMaps: [(map: ComiketMap, shape: [CGPoint])] {
        maps.compactMap { map in
            guard let shape = shape(for: map) else { return nil }
            return (map, shape)
        }
    }

    var unplacedMaps: [ComiketMap] {
        let placedIDs = Set(placedMaps.map { $0.map.id })
        return maps.filter { !placedIDs.contains($0.id) }
    }

    var showsConference: Bool {
        !placedMaps.isEmpty && !maps.contains(where: { $0.filename.hasPrefix("C") })
    }

    var contentFrame: CGRect {
        var frames = placedMaps.map { Self.bounds(of: $0.shape) }
        if showsConference {
            frames.append(Self.conferenceFrame)
        }
        guard var bounds = frames.first else { return .zero }
        for frame in frames.dropFirst() {
            bounds = bounds.union(frame)
        }
        return bounds.insetBy(dx: -2.0, dy: -2.0)
    }

    var body: some View {
        VStack(spacing: 12.0) {
            if !contentFrame.isEmpty {
                minimap(contentFrame: contentFrame)
            }
            if !unplacedMaps.isEmpty {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8.0) { unplacedMapButtons() }
                    VStack(spacing: 8.0) { unplacedMapButtons() }
                }
            }
        }
    }

    func minimap(contentFrame: CGRect) -> some View {
        let scale = width / contentFrame.width
        return ZStack {
            Canvas { context, _ in
                draw(in: context, scale: scale)
            }
            ForEach(placedMaps, id: \.map.id) { placedMap in
                let frame = Self.bounds(of: placedMap.shape)
                Button {
                    onSelect(placedMap.map)
                } label: {
                    Color.clear
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .frame(width: frame.width * scale, height: frame.height * scale)
                .position(x: (frame.midX - contentFrame.minX) * scale,
                          y: (frame.midY - contentFrame.minY) * scale)
                .accessibilityLabel(placedMap.map.name)
                .accessibilityAddTraits(placedMap.map == selection ? [.isSelected] : [])
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
        context.translateBy(x: -contentFrame.minX, y: -contentFrame.minY)

        if showsConference {
            context.fill(
                Path(Self.conferenceFrame),
                with: .color(Self.conferenceColor)
            )
            drawLabel(
                Text("Shared.Building.Conference"),
                in: Self.conferenceFrame,
                color: .white,
                context: context,
                scale: scale
            )
        }

        for placedMap in placedMaps {
            let color = Self.color(for: placedMap.map.filename)
            let isSelected = placedMap.map == selection
            let path = Self.path(of: placedMap.shape)
            context.fill(path, with: .color(color))
            if isSelected {
                context.stroke(path, with: .color(.white), lineWidth: 1.5 / scale)
            }
            drawLabel(
                Text(placedMap.map.name),
                in: Self.bounds(of: placedMap.shape),
                color: .white,
                context: context,
                scale: scale
            )
        }
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
