import SwiftUI

struct UnifiedOfflineStatus: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Oasis.self) var oasis
    @Environment(Unifier.self) var unifier

    var isVisible: Bool {
        authenticator.effectiveOnlineState == .offline && !authenticator.isAuthenticating && !oasis.isShowing
    }

    var isExpanded: Bool {
        unifier.isOfflineStatusExpanded
    }

    var isOfflineMode: Bool {
        authenticator.isOfflineModeActive
    }

    var tint: Color {
        isOfflineMode ? .pink : .orange
    }

    var body: some View {
        Group {
            if isVisible {
                VStack(alignment: .leading, spacing: 0.0) {
                    pill
                    if isExpanded {
                        VStack(alignment: .leading, spacing: 12.0) {
                            detail
                            action
                        }
                        .padding(.horizontal, 14.0)
                        .padding(.top, 2.0)
                        .padding(.bottom, 14.0)
                    }
                }
                .glassEffect(
                    isExpanded ? .regular : .regular.interactive(),
                    in: .rect(cornerRadius: isExpanded ? 22.0 : 16.0)
                )
                .contentShape(.rect)
                .onTapGesture {}
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onChange(of: authenticator.effectiveOnlineState) { _, _ in
            unifier.isOfflineStatusExpanded = false
        }
    }

    var pill: some View {
        Button {
            unifier.toggleOfflineStatus()
        } label: {
            HStack(spacing: 5.0) {
                Image(systemName: isOfflineMode ? "icloud.slash" : "wifi.exclamationmark")
                    .foregroundStyle(tint)
                Text(isOfflineMode ? "Offline.Status.Offline" : "Offline.Status.ConnectionLost")
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

    @ViewBuilder
    var detail: some View {
        if isOfflineMode, let expiryDate = authenticator.offlineModeExpiryDate {
            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                countdown(to: expiryDate, from: context.date)
                    .font(.title2.weight(.semibold).monospacedDigit())
            }
        } else if !isOfflineMode {
            VStack(alignment: .leading, spacing: 10.0) {
                Text("Offline.Status.ShowingDownloadedData")
                Text("Offline.Status.Reconnects")
            }
            .font(.subheadline)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    var action: some View {
        if isOfflineMode || authenticator.canUseOfflineMode {
            Button {
                presentOfflineModeAlert()
            } label: {
                Text(isOfflineMode ? "More.ExitOfflineMode" : "More.EnterOfflineMode")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(tint)
        }
    }

    func countdown(to expiryDate: Date, from date: Date) -> Text {
        let seconds = max(0, Int(expiryDate.timeIntervalSince(date)))
        let days = seconds / 86400
        let clock = String(format: "%02d:%02d:%02d", seconds % 86400 / 3600, seconds % 3600 / 60, seconds % 60)
        return days > 0
            ? Text("Offline.Status.TimeLeft.Days.\(days).\(clock)")
            : Text("Offline.Status.TimeLeft.\(clock)")
    }

    func presentOfflineModeAlert() {
        let isExiting = isOfflineMode
        unifier.closeOfflineStatus()
        unifier.hide()
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            if isExiting {
                unifier.isGoingToExitOfflineMode = true
            } else {
                unifier.isGoingToEnterOfflineMode = true
            }
        }
    }
}
