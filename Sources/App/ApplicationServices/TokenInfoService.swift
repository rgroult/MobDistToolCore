//
//  TokenInfoService.swift
//  App
//
//  Created by Rémi Groult on 05/06/2019.
//

import Vapor
import Meow
import Foundation

func purgeAllTokens(into context:Meow.MeowDatabase) -> EventLoopFuture<Int> {
    //return context.deleteAll(TokenInfo.self, where: Query())
    return context.collection(for: TokenInfo.self).raw.deleteAll(where: [:])
        .map { $0.deletes}
}

func purgeExpiredTokens(into context:Meow.MeowDatabase) -> EventLoopFuture<Int> {
    return context.collection(for: TokenInfo.self).raw.deleteAll(where: "expirationDate" <= Date())
        .map { $0.deletes}
     //return context.deleteAll(TokenInfo.self, where: Query.smallerThanOrEqual(field: "expirationDate", val: Date()))
}

func findTokenInfo(with tokenId:String, into context:Meow.MeowDatabase)-> EventLoopFuture<TokenInfo?>{
    let collection = context.collection(for: TokenInfo.self)
    return collection.find(where: "uuid" == tokenId)
        .firstResult()
        .map{ tokenInfo in
            guard let tokenInfo = tokenInfo else { return nil}
            if !tokenInfo.isExpired{
                return tokenInfo
            }else {
                //delete and return nil
                _ = collection.deleteOne(where: "_id" == tokenInfo._id)
             //  _ = context.delete(tokenInfo)
                return nil
            }
        }
}

func findInfo(with tokenId:String, into context:Meow.MeowDatabase)-> EventLoopFuture<[String:String]?>{
    return findTokenInfo(with: tokenId, into: context).map { $0?.value }
   /* let collection = context.collection(for: TokenInfo.self)
    return collection.find(where: "uuid" == tokenId)
    //return context.find(TokenInfo.self, where: Query.valEquals(field: "uuid", val: tokenId))
        .firstResult()
        .map{ tokenInfo in
            guard let tokenInfo = tokenInfo else { return nil}
            if !tokenInfo.isExpired{
                return tokenInfo.value
            }else {
                //delete and return nil
                _ = collection.deleteOne(where: "_id" == tokenInfo._id)
             //  _ = context.delete(tokenInfo)
                return nil
            }
        }*/
}

func store(info:[String:String], durationInSecs:TimeInterval, into context:Meow.MeowDatabase) -> EventLoopFuture<String>{
    let tokenInfo = TokenInfo(durationInSecs:durationInSecs,value:info)
    return tokenInfo.save(in: context).map { _ in tokenInfo.uuid }
    //return context.save(tokenInfo).map { tokenInfo.uuid }
}

func storeTokenInfo(info:[String:String], durationInSecs:TimeInterval, into context:Meow.MeowDatabase) -> EventLoopFuture<TokenInfo>{
    let tokenInfo = TokenInfo(durationInSecs:durationInSecs,value:info)
    return tokenInfo.save(in: context).map { _ in tokenInfo }
    //return context.save(tokenInfo).map { tokenInfo }
}

