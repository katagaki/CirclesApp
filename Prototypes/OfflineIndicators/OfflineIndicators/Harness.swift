import Observation
import SwiftUI

enum IndicatorVariant: String, CaseIterable, Identifiable {
    case current, pill, banner, toolbar, toast, panel

    var id: String { rawValue }

    var label: String {
        switch self {
        case .current: "Current gradient"
        case .pill: "1 Status pill"
        case .banner: "2 Banner"
        case .toolbar: "3 Toolbar button"
        case .toast: "4 Collapsing toast"
        case .panel: "5 Panel strip"
        }
    }
}

enum PillStyle: String, CaseIterable, Identifiable {
    case glass, tinted, solid, ring, compact

    var id: String { rawValue }

    var label: String {
        switch self {
        case .glass: "A Glass"
        case .tinted: "B Tinted glass"
        case .solid: "C Solid"
        case .ring: "D Countdown ring"
        case .compact: "E Compact"
        }
    }
}

enum ExpandedStyle: String, CaseIterable, Identifiable {
    case facts, callout, inline, timeline, panel

    var id: String { rawValue }

    var label: String {
        switch self {
        case .facts: "1 Fact rows"
        case .callout: "2 Callout"
        case .inline: "3 Inline action"
        case .timeline: "4 Timeline"
        case .panel: "5 Panel page"
        }
    }
}

enum ConnectionStatus: String, CaseIterable, Identifiable {
    case online, manual, lost

    var id: String { rawValue }

    var label: String {
        switch self {
        case .online: "Online"
        case .manual: "Offline Mode"
        case .lost: "Lost"
        }
    }
}

enum TimeLeft: String, CaseIterable, Identifiable {
    case days, hours

    var id: String { rawValue }

    var label: String {
        switch self {
        case .days: "2 days"
        case .hours: "5 hours"
        }
    }

    var interval: TimeInterval {
        switch self {
        case .days: 2 * 86400
        case .hours: 5 * 3600
        }
    }
}

enum HarnessLanguage: String, CaseIterable, Identifiable {
    case en, ja

    var id: String { rawValue }

    var label: String {
        switch self {
        case .en: "English"
        case .ja: "日本語"
        }
    }
}

enum PanelDetent: String {
    case compact, medium, large

    var detent: PresentationDetent {
        switch self {
        case .compact: .height(88)
        case .medium: .height(360)
        case .large: .large
        }
    }

    init(_ detent: PresentationDetent) {
        switch detent {
        case .height(88): self = .compact
        case .large: self = .large
        default: self = .medium
        }
    }
}

enum OfflineAlert: Identifiable {
    case enter, exit

    var id: Self { self }
}

@MainActor
@Observable
final class Harness {
    var variant: IndicatorVariant
    var pillStyle: PillStyle
    var expandedStyle: ExpandedStyle
    var status: ConnectionStatus
    var timeLeft: TimeLeft
    var language: HarnessLanguage
    var keepsGradient: Bool
    var detent: PresentationDetent
    var isDetailExpanded: Bool
    var toastPlayback = 0
    var alert: OfflineAlert?

    init() {
        let defaults = UserDefaults.standard
        variant = defaults.string(forKey: "variant").flatMap(IndicatorVariant.init) ?? .pill
        pillStyle = defaults.string(forKey: "pillStyle").flatMap(PillStyle.init) ?? .compact
        expandedStyle = defaults.string(forKey: "expandedStyle").flatMap(ExpandedStyle.init) ?? .facts
        status = defaults.string(forKey: "status").flatMap(ConnectionStatus.init) ?? .manual
        timeLeft = defaults.string(forKey: "timeLeft").flatMap(TimeLeft.init) ?? .days
        language = defaults.string(forKey: "lang").flatMap(HarnessLanguage.init) ?? .en
        keepsGradient = defaults.bool(forKey: "gradient")
        detent = (defaults.string(forKey: "detent").flatMap(PanelDetent.init) ?? .medium).detent
        isDetailExpanded = defaults.bool(forKey: "expanded")
    }

    var isOffline: Bool { status != .online }

    var showsGradient: Bool {
        isOffline && (variant == .current || keepsGradient)
    }

    var tint: Color {
        status == .lost ? .orange : .pink
    }

    var symbol: String {
        status == .lost ? "wifi.exclamationmark" : "icloud.slash"
    }

    var title: String {
        status == .lost
            ? localized("Connection Lost", "接続が切れています")
            : localized("Offline Mode", "オフラインモード")
    }

    var shortTitle: String {
        status == .lost
            ? localized("No Connection", "接続なし")
            : localized("Offline", "オフライン")
    }

    var summary: String {
        status == .lost ? localized("Reconnecting…", "再接続を待っています…") : remaining
    }

    var remaining: String {
        switch timeLeft {
        case .days: localized("2 days left", "残り2日")
        case .hours: localized("5 hours left", "残り5時間")
        }
    }

    var compactLabel: String {
        status == .lost ? title : shortTitle
    }

    var facts: [String] {
        if status == .lost {
            return [
                localized("Showing downloaded data", "ダウンロード済みのデータを表示しています"),
                localized("Reconnects on its own", "接続が戻ると自動で再開します")
            ]
        }
        return [
            localized("Available until \(expiry)", "\(expiry)まで利用できます"),
            localized("Favorites can't be edited", "お気に入りは編集できません")
        ]
    }

    var inlineNote: String {
        status == .lost
            ? localized("Showing downloaded data", "ダウンロード済みのデータを表示しています")
            : localized("Favorites can't be edited", "お気に入りは編集できません")
    }

    var calloutText: String {
        status == .lost
            ? localized(
                "Showing downloaded data until the connection returns.",
                "接続が戻るまで、ダウンロード済みのデータを表示します。"
            )
            : localized(
                "Available until \(expiry). Favorites can't be edited.",
                "\(expiry)まで利用できます。お気に入りは編集できません。"
            )
    }

    var usesPanelDetail: Bool {
        variant == .pill && pillStyle == .compact && expandedStyle == .panel && isOffline
    }

    var remainingFraction: Double {
        status == .lost ? 0.0 : timeLeft.interval / (3 * 86400)
    }

    var detail: String {
        if status == .lost {
            return localized(
                "Showing downloaded event data. CiRCLES will reconnect on its own.",
                "ダウンロード済みのイベントデータを表示しています。接続が戻ると自動で再開します。"
            )
        }
        return localized(
            "Using downloaded event data until \(expiry). Favorites can't be edited. After that, you will need to sign in again.",
            "\(expiry)まで、ダウンロード済みのイベントデータを使用します。お気に入りは編集できません。期限が過ぎると、再度ログインが必要になります。"
        )
    }

    var expiry: String {
        Date.now.addingTimeInterval(timeLeft.interval).formatted(
            .dateTime.month().day().hour().minute().locale(Locale(identifier: language.rawValue))
        )
    }

    var actionTitle: String {
        status == .lost
            ? localized("Switch to Offline Mode", "オフラインモードに切り替え")
            : localized("Exit Offline Mode", "オフラインモードを終了")
    }

    var shortActionTitle: String {
        status == .lost
            ? localized("Go Offline", "切り替え")
            : localized("Exit", "終了")
    }

    func localized(_ english: String, _ japanese: String) -> String {
        language == .ja ? japanese : english
    }

    func performAction() {
        alert = status == .lost ? .enter : .exit
    }

    func confirm(_ alert: OfflineAlert) {
        withAnimation(.smooth) {
            status = alert == .enter ? .manual : .online
            isDetailExpanded = false
        }
        toastPlayback += 1
    }

    func toggleCompactDetail() {
        isDetailExpanded.toggle()
        if usesPanelDetail && isDetailExpanded && PanelDetent(detent) == .compact {
            detent = .height(360)
        }
    }

    func selectExpandedStyle(_ style: ExpandedStyle) {
        withAnimation(.smooth) {
            expandedStyle = style
            isDetailExpanded = style != .panel
        }
    }

    func step(by offset: Int) {
        let variants = IndicatorVariant.allCases
        let index = variants.firstIndex(of: variant) ?? 0
        select(variants[(index + offset + variants.count) % variants.count])
    }

    func select(_ newVariant: IndicatorVariant) {
        withAnimation(.smooth) {
            variant = newVariant
            isDetailExpanded = false
        }
        toastPlayback += 1
    }
}
