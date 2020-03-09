//
//  JwtTokens.swift
//  App
//
//  Created by Rémi Groult on 21/02/2019.
//

import Foundation
import JWT
import JWTAuth
import Authentication

let tokenExpiration:TimeInterval = 3*60 // 3 mins
let refreshTokenExpiration:TimeInterval = 45*60 // 45mins

struct JWTTokenPayload: JWTAuthenticatable, JWTPayload, Equatable {
    
    init(_ id: String = UUID().uuidString, email:String) {
        self.id = id
        self.expireAt = ExpirationClaim(value: Date().addingTimeInterval(tokenExpiration))
        self.email = email
    }
    
    let id: String
    let email:String
    let expireAt:ExpirationClaim
    
    func verify(using signer: JWTSigner) throws {
        try self.expireAt.verifyNotExpired()
    }
    
    static func == (lhs: JWTTokenPayload, rhs: JWTTokenPayload) -> Bool {
        return lhs.id == rhs.id
    }
}


struct JWTRefreshTokenPayload: JWTAuthenticatable, JWTPayload, Equatable {
    
    init(email:String) {
        self.expireAt = ExpirationClaim(value: Date().addingTimeInterval(refreshTokenExpiration))
        self.username = email
        self.id = UUID().uuidString
    }

    let id: String
    let username:String
    let expireAt:ExpirationClaim
    
    func verify(using signer: JWTSigner) throws {
        try self.expireAt.verifyNotExpired()
    }
    
    static func == (lhs: JWTRefreshTokenPayload, rhs: JWTRefreshTokenPayload) -> Bool {
        return lhs.id == rhs.id
    }
}
