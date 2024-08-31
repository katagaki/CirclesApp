//
//  Endpoints.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/06.
//

import Foundation

 #if DEBUG
 let circleMsAuthEndpoint: URL = URL(string: "https://auth1-sandbox.circle.ms")!
 let circleMsAPIEndpoint: URL = URL(string: "https://api1-sandbox.circle.ms")!
 #else
let circleMsAuthEndpoint: URL = URL(string: "https://auth1.circle.ms")!
let circleMsAPIEndpoint: URL = URL(string: "https://api1.circle.ms")!
 #endif
