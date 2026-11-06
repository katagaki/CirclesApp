import SwiftUI

struct CompactPill: View {
    @Environment(Harness.self) private var harness

    private var style: ExpandedStyle { harness.expandedStyle }
    private var isExpanded: Bool { harness.isDetailExpanded && style != .panel }

    var body: some View {
        Group {
            switch style {
            case .callout: callout
            case .inline: inline
            case .facts, .timeline, .panel: card
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chip: some View {
        Button {
            withAnimation(.smooth) { harness.toggleCompactDetail() }
        } label: {
            HStack(spacing: 5.0) {
                Image(systemName: harness.symbol)
                    .foregroundStyle(harness.tint)
                Text(harness.compactLabel)
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .lineLimit(1)
            .padding(.horizontal, isExpanded ? 14.0 : 10.0)
            .padding(.vertical, isExpanded ? 10.0 : 7.0)
            .contentShape(.rect.inset(by: -8.0))
        }
        .buttonStyle(.plain)
    }

    private var glass: Glass {
        isExpanded ? .regular : .regular.interactive()
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            chip
            if isExpanded {
                VStack(alignment: .leading, spacing: 12.0) {
                    if style == .timeline {
                        TimelineDetail()
                    } else {
                        FactList()
                    }
                    ActionButton()
                }
                .padding(.horizontal, 14.0)
                .padding(.top, 2.0)
                .padding(.bottom, 14.0)
            }
        }
        .glassEffect(glass, in: .rect(cornerRadius: isExpanded ? 22.0 : 16.0))
    }

    private var inline: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            HStack {
                chip
                if isExpanded {
                    Spacer(minLength: 8.0)
                    Button(harness.shortActionTitle) {
                        harness.performAction()
                    }
                    .font(.caption.bold())
                    .buttonStyle(.glassProminent)
                    .tint(harness.tint)
                    .padding(.trailing, 12.0)
                }
            }
            if isExpanded {
                Text(harness.inlineNote)
                    .font(.caption)
                    .padding(.horizontal, 14.0)
                    .padding(.bottom, 10.0)
            }
        }
        .glassEffect(glass, in: .rect(cornerRadius: 16.0))
    }

    private var callout: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            chip
                .glassEffect(.regular.interactive(), in: .capsule)
            if isExpanded {
                CalloutBubble()
                    .padding(.top, 4.0)
                    .transition(.scale(scale: 0.9, anchor: .topLeading).combined(with: .opacity))
            }
        }
    }
}

struct ActionButton: View {
    @Environment(Harness.self) private var harness

    var body: some View {
        Button {
            harness.performAction()
        } label: {
            Text(harness.actionTitle)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .tint(harness.tint)
    }
}

struct FactList: View {
    @Environment(Harness.self) private var harness

    var body: some View {
        if harness.status == .manual {
            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                Text(harness.countdown(at: context.date))
                    .font(.title2.weight(.semibold).monospacedDigit())
            }
        } else {
            VStack(alignment: .leading, spacing: 10.0) {
                ForEach(harness.facts, id: \.self) { fact in
                    FactRow(text: fact)
                }
            }
        }
    }
}

struct FactRow: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct TimelineDetail: View {
    @Environment(Harness.self) private var harness

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            if harness.status == .lost {
                HStack(spacing: 8.0) {
                    ProgressView()
                        .controlSize(.small)
                    Text(harness.summary)
                        .font(.subheadline)
                }
            } else {
                VStack(spacing: 4.0) {
                    Text(harness.expiry)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    ProgressView(value: harness.remainingFraction)
                        .tint(harness.tint)
                }
            }
            Text(harness.inlineNote)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct CalloutBubble: View {
    @Environment(Harness.self) private var harness

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Text(harness.calloutText)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Button(harness.actionTitle) {
                harness.performAction()
            }
            .font(.subheadline.bold())
            .foregroundStyle(harness.tint)
        }
        .padding(12.0)
        .frame(maxWidth: 280.0, alignment: .leading)
        .background(Color(.systemBackground), in: .rect(cornerRadius: 14.0))
        .padding(.top, 7.0)
        .background(alignment: .topLeading) {
            Tail()
                .fill(Color(.systemBackground))
                .frame(width: 16.0, height: 8.0)
                .padding(.leading, 18.0)
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.18), radius: 10.0, y: 3.0)
    }
}

struct Tail: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

struct PanelDetailPage: View {
    @Environment(Harness.self) private var harness

    var body: some View {
        Form {
            Section {
                ForEach(harness.facts, id: \.self) { fact in
                    FactRow(text: fact)
                }
            }
            Section {
                ActionButton()
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
        .navigationTitle(harness.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
