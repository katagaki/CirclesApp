//
//  AttachmentAndBuysTip.swift
//  CiRCLES
//
//  Created by Claude on 2026/03/28.
//

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
