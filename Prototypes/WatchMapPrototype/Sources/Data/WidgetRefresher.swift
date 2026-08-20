import WidgetKit

enum WidgetRefresher {
    static func reload() {
        WidgetCenter.shared.reloadTimelines(ofKind: "NextStopWidget")
    }
}
