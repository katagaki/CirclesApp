import SwiftUI
import WidgetKit

struct NextStopView: View {

    let entry: NextStopEntry
    let family: WidgetFamily

    var body: some View {
        switch family {
        case .accessoryRectangular: rectangular
        case .accessoryCircular: circular
        case .accessoryInline: Text("\(entry.spaceLabel) · \(entry.hallName)")
        case .accessoryCorner:
            Text(entry.spaceLabel)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .widgetCurvesContent()
                .widgetLabel(entry.hallName)
        default: rectangular
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            HStack(spacing: 3.0) {
                Circle()
                    .fill(entry.color)
                    .frame(width: 6.0, height: 6.0)
                Text("NEXT · \(entry.position)/\(entry.total)")
                    .font(.system(size: 11.0, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Text(entry.spaceLabel)
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(entry.buyCount > 0
                 ? "\(entry.hallName) · \(entry.buyCount) items"
                 : entry.hallName)
                .font(.system(size: 12.0))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var circular: some View {
        Gauge(value: Double(entry.position), in: 1.0...Double(max(entry.total, 1))) {
            Text(entry.spaceLabel)
                .font(.system(size: 13.0, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(entry.color)
    }
}
