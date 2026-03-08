//
//  Endpoints.swift
//  RADiUS
//
//  Created by シン・ジャスティン on 2024/07/06.
//

import Foundation

#if DEBUG
public let circleMsAuthEndpoint: URL = URL(string: "https://auth1-sandbox.circle.ms")! // NOSONAR
public let circleMsAPIEndpoint: URL = URL(string: "https://api1-sandbox.circle.ms")! // NOSONAR
#else
public let circleMsAuthEndpoint: URL = URL(string: "https://auth1.circle.ms")! // NOSONAR
public let circleMsAPIEndpoint: URL = URL(string: "https://api1.circle.ms")! // NOSONAR
#endif

public let circleMsCancelURLSchema: String = """
circles-app:/?error=access_denied&error_description=user%20access%20denied&state=auth
"""
