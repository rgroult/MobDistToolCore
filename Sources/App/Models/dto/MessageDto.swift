//
//  MessageDto.swift
//  App
//
//  Created by Rémi Groult on 14/02/2019.
//

import Foundation
import Vapor

struct MessageDto: Codable {
    var message:String
}

extension MessageDto {
    static func sample() -> MessageDto {
        return MessageDto( message: "Message")
    }
}

extension MessageDto: Content {}
