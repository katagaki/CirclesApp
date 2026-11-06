import SwiftUI

struct IndicatorLayer: View {
    @Environment(Harness.self) private var harness

    var body: some View {
        Group {
            if harness.isOffline {
                switch harness.variant {
                case .pill: PillIndicator()
                case .banner: BannerIndicator()
                case .toast: ToastIndicator()
                case .current, .toolbar, .panel: EmptyView()
                }
            }
        }
        .padding(.horizontal, 12.0)
        .padding(.top, 8.0)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.smooth, value: harness.status)
    }
}

struct DetailContent: View {
    @Environment(Harness.self) private var harness

    var body: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            Text(harness.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(harness.actionTitle) {
                harness.performAction()
            }
            .buttonStyle(.glassProminent)
            .tint(harness.tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PillIndicator: View {
    @Environment(Harness.self) private var harness

    var body: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            Button {
                withAnimation(.smooth) { harness.isDetailExpanded.toggle() }
            } label: {
                HStack(spacing: 6.0) {
                    Image(systemName: harness.symbol)
                        .foregroundStyle(harness.tint)
                    Text(harness.title)
                        .fontWeight(.semibold)
                    Text(harness.summary)
                        .foregroundStyle(.secondary)
                    Image(systemName: harness.isDetailExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
                .font(.footnote)
                .lineLimit(1)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            if harness.isDetailExpanded {
                DetailContent()
            }
        }
        .padding(.horizontal, 14.0)
        .padding(.vertical, 10.0)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20.0))
    }
}

struct BannerIndicator: View {
    @Environment(Harness.self) private var harness

    var body: some View {
        HStack(spacing: 10.0) {
            Image(systemName: harness.symbol)
                .font(.title3)
            VStack(alignment: .leading, spacing: 0.0) {
                Text(harness.title)
                    .font(.subheadline.bold())
                Text(harness.summary)
                    .font(.caption)
            }
            Spacer(minLength: 0.0)
            Button(harness.shortActionTitle) {
                harness.performAction()
            }
            .font(.subheadline.bold())
            .foregroundStyle(harness.tint)
            .padding(.horizontal, 14.0)
            .padding(.vertical, 7.0)
            .background(.white, in: .capsule)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14.0)
        .padding(.vertical, 10.0)
        .background(harness.tint.mix(with: .black, by: 0.15), in: .rect(cornerRadius: 16.0))
    }
}

struct ToolbarIndicator: View {
    @Environment(Harness.self) private var harness

    var body: some View {
        Menu {
            Section("\(harness.title) · \(harness.summary)") {
                Text(harness.detail)
                Button(harness.actionTitle) {
                    harness.performAction()
                }
            }
        } label: {
            Image(systemName: harness.symbol)
                .foregroundStyle(harness.tint)
        }
        .accessibilityLabel(harness.title)
    }
}

struct ToastIndicator: View {
    @Environment(Harness.self) private var harness
    @State private var isExpanded = true
    @Namespace private var namespace

    var body: some View {
        GlassEffectContainer {
            Group {
                if isExpanded {
                    expanded
                } else {
                    chip
                }
            }
            .glassEffectID("toast", in: namespace)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: "\(harness.toastPlayback)-\(harness.status.rawValue)") {
            withAnimation(.smooth) { isExpanded = true }
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled else { return }
            withAnimation(.smooth) { isExpanded = false }
        }
    }

    private var expanded: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            HStack(spacing: 8.0) {
                Image(systemName: harness.symbol)
                    .foregroundStyle(harness.tint)
                Text(harness.title)
                    .font(.headline)
                Spacer(minLength: 0.0)
                Text(harness.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            DetailContent()
        }
        .padding(14.0)
        .glassEffect(.regular, in: .rect(cornerRadius: 20.0))
    }

    private var chip: some View {
        Button {
            harness.toastPlayback += 1
        } label: {
            HStack(spacing: 5.0) {
                Image(systemName: harness.symbol)
                    .foregroundStyle(harness.tint)
                Text(harness.shortTitle)
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .padding(.horizontal, 10.0)
            .padding(.vertical, 7.0)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}

struct PanelStrip: View {
    @Environment(Harness.self) private var harness

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            Button {
                withAnimation(.smooth) { harness.isDetailExpanded.toggle() }
            } label: {
                HStack(spacing: 8.0) {
                    Image(systemName: harness.symbol)
                        .foregroundStyle(harness.tint)
                    Text(harness.title)
                        .font(.subheadline.bold())
                    Spacer(minLength: 0.0)
                    Text(harness.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.down")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(harness.isDetailExpanded ? 180.0 : 0.0))
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            if harness.isDetailExpanded {
                DetailContent()
            }
        }
        .padding(.horizontal, 14.0)
        .padding(.vertical, 10.0)
        .background(harness.tint.opacity(0.14), in: .rect(cornerRadius: 16.0))
        .padding(.horizontal, 16.0)
        .padding(.bottom, 6.0)
    }
}
