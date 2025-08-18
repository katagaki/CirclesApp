//
//  MapView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/18.
//

import Komponents
import SwiftData
import SwiftUI

struct MapView: View {
    @Namespace var namespace

    var body: some View {
        InteractiveMap(namespace: namespace)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("ViewTitle.Map")
            .navigationBarTitleDisplayMode(.inline)
    }
}
