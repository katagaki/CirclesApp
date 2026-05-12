//
//  EventDataStorageBar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/05/12.
//

import SwiftUI

struct EventDataStorageBreakdown: Sendable {
    let databaseBytes: Int64
    let imageCacheBytes: Int64
    var totalBytes: Int64 { databaseBytes + imageCacheBytes }
}

struct EventDataStorageStats: Sendable {
    let totalCapacity: Int64
    let availableCapacity: Int64
    let breakdown: EventDataStorageBreakdown

    var circlesBytes: Int64 { breakdown.totalBytes }
    var usedByOtherApps: Int64 {
        max(0, totalCapacity - availableCapacity - circlesBytes)
    }

    static func current(breakdown: EventDataStorageBreakdown) -> EventDataStorageStats {
        let url = URL(fileURLWithPath: NSHomeDirectory() as String)
        let values = try? url.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ])
        let total = Int64(values?.volumeTotalCapacity ?? 0)
        let available = values?.volumeAvailableCapacityForImportantUsage ?? 0
        return EventDataStorageStats(
            totalCapacity: total,
            availableCapacity: available,
            breakdown: breakdown
        )
    }
}

struct EventDataStorageSegment: Identifiable, Sendable {
    enum Kind { case circles, other, free }
    let id = UUID()
    let kind: Kind
    let label: String
    let color: Color
    let bytes: Int64
}

struct EventDataStorageBar: View {

    let stats: EventDataStorageStats?

    var body: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            BarView(segments: segments, totalCapacity: stats?.totalCapacity ?? 0)
            LegendView(segments: segments)
        }
        .padding(.vertical, 8.0)
    }

    private var circlesSegments: [EventDataStorageSegment] {
        let breakdown = stats?.breakdown ?? EventDataStorageBreakdown(
            databaseBytes: 0, imageCacheBytes: 0
        )
        return [
            EventDataStorageSegment(
                kind: .circles,
                label: "CiRCLES",
                color: .accentColor,
                bytes: breakdown.databaseBytes
            ),
            EventDataStorageSegment(
                kind: .circles,
                label: String(localized: "More.DBAdmin.ImageCache"),
                color: .purple,
                bytes: breakdown.imageCacheBytes
            )
        ]
    }

    private var segments: [EventDataStorageSegment] {
        guard let stats, stats.totalCapacity > 0 else {
            return circlesSegments
        }
        var result: [EventDataStorageSegment] = [
            EventDataStorageSegment(
                kind: .other,
                label: String(localized: "More.Storage.OtherApps"),
                color: .gray,
                bytes: stats.usedByOtherApps
            )
        ]
        result.append(contentsOf: circlesSegments)
        result.append(EventDataStorageSegment(
            kind: .free,
            label: String(localized: "More.Storage.Free"),
            color: Color(.systemGray5),
            bytes: stats.availableCapacity
        ))
        return result
    }
}

private struct BarView: View {

    let segments: [EventDataStorageSegment]
    let totalCapacity: Int64

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0.0) {
                ForEach(segments) { segment in
                    let width = widthFor(segment, totalWidth: geometry.size.width)
                    if width > 0 {
                        segment.color.frame(width: width)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6.0))
        }
        .frame(height: 16.0)
    }

    private func widthFor(_ segment: EventDataStorageSegment, totalWidth: CGFloat) -> CGFloat {
        guard denominator > 0 else { return 0 }
        let fraction = CGFloat(segment.bytes) / CGFloat(denominator)
        return max(0, totalWidth * fraction)
    }

    private var denominator: Int64 {
        if totalCapacity > 0 { return totalCapacity }
        return max(1, segments.reduce(0) { $0 + $1.bytes })
    }
}

private struct LegendView: View {

    let segments: [EventDataStorageSegment]

    var body: some View {
        VStack(alignment: .leading, spacing: 6.0) {
            ForEach(segments) { segment in
                HStack(spacing: 8.0) {
                    Circle()
                        .fill(segment.color)
                        .frame(width: 10.0, height: 10.0)
                    Text(segment.label)
                        .font(.subheadline)
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: segment.bytes, countStyle: .file))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
    }
}
