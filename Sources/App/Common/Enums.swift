//
//  Enums.swift
//  App
//
//  Created by Rémi Groult on 21/02/2019.
//

import Foundation
import Vapor

enum ModelVisibility:Int {
    case light, full
}

enum Platform:String,Codable {
    case ios, android
}

extension Platform {
    static func create(from value:String) throws -> Platform {
        guard let platform = Platform(rawValue:value) else {
            let error = Abort(.badRequest,reason: "Bad parameter platorm, values are [\(Platform.ios),\(Platform.android)]")
            throw error }
        return platform
    }
}
