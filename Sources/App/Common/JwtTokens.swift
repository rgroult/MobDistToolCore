//
//  JwtTokens.swift
//  App
//
//  Created by Rémi Groult on 21/02/2019.
//

import Foundation
import JWT
import JWTAuth

let tokenExpiration:TimeInterval = 3*60 // 3 mins
let refreshTokenExpiration:TimeInterval = 16*60 // 15mins

struct JWTTokenPayload: JWTAuthenticatable, JWTPayload, Equatable {
    
    init(_ id: String = UUID().uuidString, email:String) {
        self.id = id
        self.expireAt = Date().addingTimeInterval(tokenExpiration)
        self.email = email
    }
    
    let id: String
    let email:String
    let expireAt:Date
    
    func verify(using signer: JWTSigner) throws {
        print("verify")
        guard Date().addingTimeInterval(tokenExpiration) < expireAt else {
            print("WARNING : token expired")
            return
        }
    }
    
    static func == (lhs: JWTTokenPayload, rhs: JWTTokenPayload) -> Bool {
        return lhs.id == rhs.id
    }
}

/*
struct JWTRefreshTokenPayload: JWTAuthenticatable, JWTPayload, Equatable {
    
    init(_ id: String = UUID().uuidString) {
        self.id = id
        self.expireAt = Date().addingTimeInterval(refreshTokenExpiration)
    }
    
    let id: String
    let expireAt:Date
    
    func verify(using signer: JWTSigner) throws {
        guard Date().addingTimeInterval(tokenExpiration) < expireAt else {
            print("WARNING : token expired")
            return
        }
    }
    
    static func == (lhs: JWTRefreshTokenPayload, rhs: JWTRefreshTokenPayload) -> Bool {
        return lhs.id == rhs.id
    }
}*/
