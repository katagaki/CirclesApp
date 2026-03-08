//
//  Date.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/15.
//

import Foundation

extension Date: @retroactive Identifiable {
    public var id: String {
        self.ISO8601Format()
    }
}
