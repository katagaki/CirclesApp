//
//  GenreOverlayTip.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/01.
//

import Foundation
import TipKit

struct GenreOverlayTip: Tip {
    var title: Text {
        Text("Tip.GenreOverlay.Title")
    }
    var message: Text? {
        Text("Tip.GenreOverlay.Description")
    }
    var image: Image? {
        Image(systemName: "theatermask.and.paintbrush")
    }
}
