//
//  EventDataRows.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/05/12.
//

import SwiftUI
import RADiUS

struct DownloadedEventRow: View {

    let info: DownloadedEventInfo
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8.0) {
                Text("Shared.Event.\(info.number)")
                    .foregroundStyle(.primary)
                Spacer()
                Text(ByteCountFormatter.string(fromByteCount: info.bytes, countStyle: .file))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct DownloadableEventRow: View {

    let event: WebCatalogEvent.Response.Event
    let progress: Double?
    let isDownloading: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: isDownloading ? {} : onTap) {
            HStack(spacing: 8.0) {
                Text("Shared.Event.\(event.number)")
                    .tint(.primary)
                Spacer()
                if isDownloading {
                    DownloadProgressDonut(progress: progress)
                } else {
                    Image(systemName: "icloud.and.arrow.down")
                        .foregroundStyle(.accent)
                }
            }
            .contentShape(Rectangle())
        }
    }
}

struct DownloadProgressDonut: View {

    let progress: Double?

    private var accent: Color { Color("AccentColor") }

    var body: some View {
        ZStack {
            Circle()
                .stroke(accent.opacity(0.25), lineWidth: 2.0)
            if let progress {
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(max(progress, 0.0), 1.0)))
                    .stroke(accent, style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.15), value: progress)
            } else {
                Circle()
                    .trim(from: 0.0, to: 0.2)
                    .stroke(accent, style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .modifier(SpinningModifier())
            }
        }
        .frame(width: 20.0, height: 20.0)
    }
}

struct SpinningModifier: ViewModifier {

    @State private var isSpinning: Bool = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isSpinning ? 360.0 : 0.0))
            .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isSpinning)
            .onAppear { isSpinning = true }
    }
}
