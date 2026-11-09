import SwiftUI

struct DockBar: View {

    @Environment(Harness.self) var harness
    @Binding var selection: DockTab

    var body: some View {
        HStack(spacing: 0.0) {
            ForEach(DockTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 3.0) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 19.0))
                            .overlay(alignment: .topTrailing) {
                                if tab == .buys && harness.isSharedBuysActive {
                                    Circle().fill(.purple).frame(width: 8.0, height: 8.0).offset(x: 5.0, y: -2.0)
                                }
                            }
                        Text(tab.title).font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(selection == tab ? Color.accentColor : Color.secondary)
                    .frame(maxWidth: .infinity, minHeight: 50.0)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8.0)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 16.0)
        .padding(.bottom, 8.0)
    }
}
