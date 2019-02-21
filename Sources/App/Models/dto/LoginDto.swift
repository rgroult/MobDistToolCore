//
//  LoginDto.swift
//  App
//
//  Created by Rémi Groult on 14/02/2019.
//

import Foundation
import MeowVapor

struct LoginReqDto: Codable {
    var email:String
    var password:String
}

struct LoginRespDto: Codable {
    var email:String
    var name:String
    var token:String
   // var refreshToken:String
}

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension LoginRespDto: Content { }
