//
//  LoginDto.swift
//  App
//
//  Created by Rémi Groult on 14/02/2019.
//

import Foundation
import Vapor

public struct LoginReqDto: Codable, Content {
    var email:String
    var password:String
}

public struct LoginRespDto: Codable {
    public var email:String
    public var name:String
    public var token:String
    public var refreshToken:String?
}

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension LoginRespDto: Content { }

public struct RefreshTokenDto: Codable, Content {
    var email:String
    var refreshToken:String
}

