//
//  BarButtonLabelStyle.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/08.
//

import SwiftUI

struct BarButtonLabelStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
        configuration.icon.font(.headline)
        configuration.title.font(.body)
    }
  }
}
