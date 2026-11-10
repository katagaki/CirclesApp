import SwiftUI

struct TodayReadinessCard: View {

    @Environment(Harness.self) var harness

    var body: some View {
        TodayCard(title: "Event Data", symbol: Feature.eventData.symbol, tint: harness.isOffline ? .orange : .green,
                  destination: .eventData) {
            HStack(spacing: 12.0) {
                Image(systemName: harness.isOffline ? "wifi.slash" : "checkmark.icloud.fill")
                    .font(.title2)
                    .foregroundStyle(harness.isOffline ? .orange : .green)
                    .frame(width: 32.0)
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(harness.isOffline ? "You're offline" : "Event data downloaded").font(.headline)
                    Text(harness.isOffline ? "Map, catalog and lists still work; changes sync later"
                                           : "C107 catalog, cuts and maps · works offline")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
