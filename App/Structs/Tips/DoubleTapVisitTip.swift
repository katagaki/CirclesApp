import Foundation
import TipKit

struct DoubleTapVisitTip: Tip {
    var title: Text {
        Text("Tip.DoubleTapVisit.Title")
    }
    var message: Text? {
        Text("Tip.DoubleTapVisit.Description")
    }
    var image: Image? {
        Image(systemName: "hand.tap.fill")
    }
}
