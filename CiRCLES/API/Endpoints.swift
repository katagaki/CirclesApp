//
//  Endpoints.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/06.
//

import Foundation

#if DEBUG
let circlesAuthEndpoint: URL = URL(string: "https://auth1-sandbox.circle.ms")!
let circlesAPIEndpoint: URL = URL(string: "https://api1-sandbox.circle.ms")!
#else
// TODO: Force sandbox until app is ready for production server
let circlesAuthEndpoint: URL = URL(string: "https://auth1-sandbox.circle.ms")!
let circlesAPIEndpoint: URL = URL(string: "https://api1-sandbox.circle.ms")!
//let circlesAuthEndpoint: URL = URL(string: "https://auth1.circle.ms")!
//let circlesAPIEndpoint: URL = URL(string: "https://api1.circle.ms")!
#endif
