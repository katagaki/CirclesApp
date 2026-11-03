import Foundation
import TipKit

struct BuysScopeTip: Tip {
    var title: Text {
        Text("Tip.BuysScope.Title")
    }
    var message: Text? {
        Text("Tip.BuysScope.Description")
    }
    var image: Image? {
        Image(systemName: "person.2")
    }
}
