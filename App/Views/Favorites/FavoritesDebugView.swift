//
//  FavoritesDebugView.swift
//  CiRCLES
//
//  Created by Claude on 2026/08/14.
//

import SwiftUI
import RADiUS

// Diagnostic view, so strings are intentionally verbatim and not localized.
@MainActor
struct FavoritesDebugView: View {

    @Environment(\.dismiss) var dismiss

    @State var debug = FavoritesDebug.shared
    @State var selectedCaptureID: UUID?
    @State var isShowingRawJSON: Bool = false

    var selectedCapture: FavoritesDebugCapture? {
        if let selectedCaptureID,
           let capture = debug.captures.first(where: { $0.id == selectedCaptureID }) {
            return capture
        }
        return debug.captures.first
    }

    var body: some View {
        NavigationStack {
            Group {
                if let capture = selectedCapture {
                    List {
                        captureSection(capture)
                        unmappedSection(capture)
                        colorCodeSection(capture)
                        entriesSection(capture)
                    }
                } else {
                    ContentUnavailableView {
                        Label {
                            Text(verbatim: "No responses captured")
                        } icon: {
                            Image(systemName: "arrow.down.circle.dotted")
                        }
                    } description: {
                        Text(verbatim: "Pull to refresh the Favorites list, then reopen this view.")
                    }
                }
            }
            .navigationTitle(Text(verbatim: "Favorites Debug"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text(verbatim: "Done")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    menu()
                }
            }
            .sheet(isPresented: $isShowingRawJSON) {
                if let rawJSON = selectedCapture?.rawJSON {
                    FavoritesDebugRawJSONView(rawJSON: rawJSON)
                }
            }
        }
    }

    @ViewBuilder
    func menu() -> some View {
        Menu {
            if debug.captures.count > 1 {
                Picker(selection: $selectedCaptureID) {
                    ForEach(debug.captures) { capture in
                        Text(verbatim: "\(capture.source.rawValue) — "
                             + capture.date.formatted(date: .omitted, time: .standard))
                        .tag(Optional(capture.id))
                    }
                } label: {
                    Text(verbatim: "Capture")
                }
                Divider()
            }
            if selectedCapture?.rawJSON != nil {
                Button {
                    isShowingRawJSON = true
                } label: {
                    Label {
                        Text(verbatim: "View raw JSON")
                    } icon: {
                        Image(systemName: "curlybraces")
                    }
                }
            }
            if let capture = selectedCapture {
                Button {
                    UIPasteboard.general.string = summary(for: capture)
                } label: {
                    Label {
                        Text(verbatim: "Copy summary")
                    } icon: {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }
            Divider()
            Button(role: .destructive) {
                debug.clear()
                selectedCaptureID = nil
            } label: {
                Label {
                    Text(verbatim: "Clear captures")
                } icon: {
                    Image(systemName: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    @ViewBuilder
    func captureSection(_ capture: FavoritesDebugCapture) -> some View {
        Section {
            LabeledContent {
                Text(verbatim: capture.source.rawValue)
            } label: {
                Text(verbatim: "Source")
            }
            LabeledContent {
                Text(verbatim: capture.date.formatted(date: .abbreviated, time: .standard))
            } label: {
                Text(verbatim: "Captured")
            }
            if let status = capture.status {
                LabeledContent {
                    Text(verbatim: status)
                } label: {
                    Text(verbatim: "Status")
                }
            }
            if capture.byteCount > 0 {
                LabeledContent {
                    Text(verbatim: "\(capture.byteCount) bytes")
                } label: {
                    Text(verbatim: "Payload")
                }
            }
            LabeledContent {
                Text(verbatim: "\(capture.entries.count)")
            } label: {
                Text(verbatim: "Favorites")
            }
            if let note = capture.note {
                Text(verbatim: note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(verbatim: "Response")
        }
    }

    @ViewBuilder
    func unmappedSection(_ capture: FavoritesDebugCapture) -> some View {
        let unmapped = capture.unmappedCodes
        Section {
            if unmapped.isEmpty {
                Label {
                    Text(verbatim: "Every color code maps to a known case.")
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                .font(.subheadline)
            } else {
                ForEach(unmapped.keys.sorted(), id: \.self) { code in
                    LabeledContent {
                        Text(verbatim: "\(unmapped[code] ?? 0) favorite(s)")
                    } label: {
                        Label {
                            Text(verbatim: "Code \(code)")
                                .monospaced()
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                Text(verbatim: """
                     These codes have no WebCatalogColor case, so they decode to \
                     .uncolored and render gray.
                     """)
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        } header: {
            Text(verbatim: "Unrecognized color codes")
        }
    }

    @ViewBuilder
    func colorCodeSection(_ capture: FavoritesDebugCapture) -> some View {
        let counts = capture.colorCodeCounts
        if !counts.isEmpty {
            Section {
                ForEach(counts.keys.sorted(), id: \.self) { code in
                    let color = WebCatalogColor(rawValue: code)
                    HStack(spacing: 12.0) {
                        swatch(for: color)
                        VStack(alignment: .leading, spacing: 2.0) {
                            Text(verbatim: "Code \(code)")
                                .monospaced()
                            Text(verbatim: color?.name() ?? "Unmapped")
                                .font(.caption)
                                .foregroundStyle(color == nil ? Color.orange : Color.secondary)
                        }
                        Spacer()
                        Text(verbatim: "\(counts[code] ?? 0)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            } header: {
                Text(verbatim: "Color codes in response")
            }
        }
    }

    @ViewBuilder
    func entriesSection(_ capture: FavoritesDebugCapture) -> some View {
        if !capture.entries.isEmpty {
            Section {
                ForEach(capture.entries) { entry in
                    HStack(spacing: 12.0) {
                        swatch(for: entry.mappedColor)
                        VStack(alignment: .leading, spacing: 2.0) {
                            Text(verbatim: entry.circleName)
                                .lineLimit(1)
                            HStack(spacing: 4.0) {
                                Text(verbatim: "wcid \(entry.webCatalogID.map({ String($0) }) ?? "-")")
                                Text(verbatim: "·")
                                Text(verbatim: "color \(entry.rawColor.map({ String($0) }) ?? "-")")
                                    .foregroundStyle(entry.isUnmapped ? Color.orange : Color.secondary)
                            }
                            .font(.caption)
                            .monospaced()
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if entry.isUnmapped {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            } header: {
                Text(verbatim: "Favorites")
            }
        }
    }

    @ViewBuilder
    func swatch(for color: WebCatalogColor?) -> some View {
        RoundedRectangle(cornerRadius: 4.0)
            .fill(color?.backgroundColor() ?? Color.clear)
            .overlay {
                RoundedRectangle(cornerRadius: 4.0)
                    .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1.0)
            }
            .overlay {
                if color == nil {
                    Image(systemName: "questionmark")
                        .font(.system(size: 10.0))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 22.0, height: 22.0)
    }

    func summary(for capture: FavoritesDebugCapture) -> String {
        var lines: [String] = []
        lines.append("Source: \(capture.source.rawValue)")
        lines.append("Captured: \(capture.date.formatted(date: .abbreviated, time: .standard))")
        if let status = capture.status {
            lines.append("Status: \(status)")
        }
        lines.append("Favorites: \(capture.entries.count)")
        lines.append("")
        lines.append("Color code counts (code -> count, mapped name):")
        let counts = capture.colorCodeCounts
        for code in counts.keys.sorted() {
            let name = WebCatalogColor(rawValue: code)?.name() ?? "UNMAPPED"
            lines.append("  \(code) -> \(counts[code] ?? 0) (\(name))")
        }
        return lines.joined(separator: "\n")
    }
}

@MainActor
struct FavoritesDebugRawJSONView: View {

    @Environment(\.dismiss) var dismiss

    let rawJSON: String

    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                Text(verbatim: rawJSON)
                    .font(.system(size: 11.0, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
            }
            .navigationTitle(Text(verbatim: "Raw JSON"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text(verbatim: "Done")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIPasteboard.general.string = rawJSON
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }
        }
    }
}
