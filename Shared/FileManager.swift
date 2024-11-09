//
//  FileManager.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/09.
//

import Foundation

let documentsDirectoryURL = FileManager.default.urls(
    for: .documentDirectory,
    in: .userDomainMask
).first
