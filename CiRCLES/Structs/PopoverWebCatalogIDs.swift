//
//  PopoverWebCatalogIDs.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/07.
//

struct WebCatalogIDSet: Identifiable {
    var ids: [Int]

    var id: String {
        ids.description
    }
}
