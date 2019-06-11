//
//  TokenInfoService.swift
//  App
//
//  Created by Rémi Groult on 05/06/2019.
//

import Vapor
import Meow
import Foundation

func purgeAllTokens(into context:Meow.Context) -> Future<Int> {
    return context.deleteAll(TokenInfo.self, where: Query())
}

func purgeExpiredTokens(into context:Meow.Context) -> Future<Int> {
     return context.deleteAll(TokenInfo.self, where: Query.smallerThanOrEqual(field: "expirationDate", val: Date()))
}

func findInfo(with tokenId:String, into context:Meow.Context)-> Future<[String:String]?>{
    return context.find(TokenInfo.self, where: Query.valEquals(field: "uuid", val: tokenId))
        .getFirstResult()
        .map{ tokenInfo in
            guard let tokenInfo = tokenInfo else { return nil}
            if !tokenInfo.isExpired{
                return tokenInfo.value
            }else {
                //delete and return nil
               _ = context.delete(tokenInfo)
                return nil
            }
        }
}

func store(info:[String:String], durationInSecs:TimeInterval, into context:Meow.Context) -> Future<String>{
    let tokenInfo = TokenInfo(durationInSecs:durationInSecs,value:info)
    return context.save(tokenInfo).map { tokenInfo.uuid }
}
