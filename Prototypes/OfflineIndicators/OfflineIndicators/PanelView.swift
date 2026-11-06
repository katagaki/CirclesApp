import SwiftUI

struct PanelView: View {
    @Environment(Harness.self) private var harness

    private var isCompact: Bool {
        PanelDetent(harness.detent) == .compact
    }

    private var showsPanelStrip: Bool {
        harness.variant == .panel && harness.isOffline
    }

    private var showsPillInPanel: Bool {
        harness.variant == .pill && harness.isOffline && PanelDetent(harness.detent) == .large
    }

    var body: some View {
        @Bindable var harness = harness
        Group {
            if isCompact {
                compactBar
            } else {
                NavigationStack {
                    controls
                        .navigationTitle("Harness")
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationDestination(isPresented: isPanelDetailPresented) {
                            PanelDetailPage()
                        }
                        .safeAreaInset(edge: .top, spacing: 0.0) {
                            if showsPanelStrip {
                                PanelStrip()
                            } else if showsPillInPanel {
                                PillIndicator()
                                    .padding(.horizontal, 16.0)
                                    .padding(.bottom, 6.0)
                            }
                        }
                }
            }
        }
        .alert(alertTitle, isPresented: isAlertPresented, presenting: harness.alert) { alert in
            Button(harness.localized("Cancel", "キャンセル"), role: .cancel) {}
            Button(alert == .enter ? enterTitle : exitTitle) {
                harness.confirm(alert)
            }
        } message: { alert in
            Text(alert == .enter ? enterMessage : exitMessage)
        }
    }

    private var isPanelDetailPresented: Binding<Bool> {
        Binding(
            get: { harness.usesPanelDetail && harness.isDetailExpanded },
            set: { harness.isDetailExpanded = $0 }
        )
    }

    private var compactBar: some View {
        HStack(spacing: 10.0) {
            HStack {
                Button("Previous", systemImage: "chevron.left") { harness.step(by: -1) }
                    .labelStyle(.iconOnly)
                Spacer(minLength: 0.0)
                Text(harness.variant.label)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Spacer(minLength: 0.0)
                Button("Next", systemImage: "chevron.right") { harness.step(by: 1) }
                    .labelStyle(.iconOnly)
            }
            .padding(.horizontal, 14.0)
            .frame(maxWidth: .infinity, minHeight: 48.0)
            .glassEffect(.regular.interactive(), in: .capsule)
            if showsPanelStrip {
                Button {
                    harness.isDetailExpanded = true
                    harness.detent = .height(360)
                } label: {
                    Image(systemName: harness.symbol)
                        .foregroundStyle(harness.tint)
                        .frame(width: 48.0, height: 48.0)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(harness.tint.opacity(0.2)).interactive(), in: .circle)
                .accessibilityLabel(harness.title)
            }
        }
        .padding(.horizontal, 20.0)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 20.0)
    }

    private var controls: some View {
        @Bindable var harness = harness
        return Form {
            Section {
                Picker("Indicator", selection: Binding(
                    get: { harness.variant },
                    set: { harness.select($0) }
                )) {
                    ForEach(IndicatorVariant.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.menu)
                if harness.variant == .pill {
                    Picker("Pill style", selection: $harness.pillStyle) {
                        ForEach(PillStyle.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.menu)
                    if harness.pillStyle == .compact {
                        Picker("Expanded view", selection: Binding(
                            get: { harness.expandedStyle },
                            set: { harness.selectExpandedStyle($0) }
                        )) {
                            ForEach(ExpandedStyle.allCases) { Text($0.label).tag($0) }
                        }
                        .pickerStyle(.menu)
                    }
                }
                Toggle("Keep the gradient too", isOn: $harness.keepsGradient)
                    .disabled(harness.variant == .current)
                if harness.variant == .toast {
                    Button("Replay toast") { harness.toastPlayback += 1 }
                }
            }
            Section {
                segmented($harness.status, ConnectionStatus.allCases) { $0.label }
                segmented($harness.timeLeft, TimeLeft.allCases) { $0.label }
                    .disabled(harness.status != .manual)
                segmented($harness.language, HarnessLanguage.allCases) { $0.label }
            }
        }
    }

    private func segmented<Value: Hashable & Identifiable>(
        _ selection: Binding<Value>,
        _ values: [Value],
        label: @escaping (Value) -> String
    ) -> some View {
        Picker("", selection: selection) {
            ForEach(values) { Text(label($0)).tag($0) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var isAlertPresented: Binding<Bool> {
        Binding(
            get: { harness.alert != nil },
            set: { if !$0 { harness.alert = nil } }
        )
    }

    private var alertTitle: String {
        harness.alert == .enter
            ? harness.localized("Are You At The Venue?", "会場にいますか？")
            : harness.localized("Exit Offline Mode?", "オフラインモードを終了しますか？")
    }

    private var enterTitle: String {
        harness.localized("Switch to Offline Mode", "オフラインモードに切り替え")
    }

    private var exitTitle: String {
        harness.localized("Exit Offline Mode", "オフラインモードを終了")
    }

    private var enterMessage: String {
        harness.localized(
            "In offline mode, you can use CiRCLES for 3 days with previously downloaded event data. After that, you will need to sign in again. Favorites cannot be edited in offline mode.",
            "オフラインモードでは、事前にダウンロードしたイベントデータを使用して、3日間サークルズをご利用いただけます。期限が過ぎると、再度ログインが必要になります。なお、オフラインモードではお気に入りの編集はできません。"
        )
    }

    private var exitMessage: String {
        harness.localized(
            "You will need to sign in again after exiting offline mode.",
            "終了すると、再度ログインが必要になります。"
        )
    }
}
