import Foundation
import TipKit

struct AttachmentAndBuysTip: Tip {
    var title: Text {
        Text("Tip.AttachmentAndBuys.Title")
    }
    var message: Text? {
        Text("Tip.AttachmentAndBuys.Description")
    }
    var image: Image? {
        Image(systemName: "photo.on.rectangle.angled")
    }
}
