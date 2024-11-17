//
//  VisitModeTip.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/17.
//

import Foundation
import TipKit

struct VisitModeTip: Tip {
    var title: Text {
        Text("Tip.VisitMode.Title")
    }
    var message: Text? {
        Text("Tip.VisitMode.Description")
    }
    var image: Image? {
        Image(systemName: "checkmark.rectangle.stack")
    }
}
