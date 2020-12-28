//
//  TokenInfo.swift
//  App
//
//  Created by Rémi Groult on 05/06/2019.
//

import Vapor
import Meow
import MongoKitten

final class TokenInfo: BaseModel,ReadableModel {
    var _id = ObjectId()
    var uuid:String
    var expirationDate:Date
    var value:[String:String]
    var isExpired:Bool{
        return Date() >= expirationDate
    }
    
    init(durationInSecs:TimeInterval,value:[String:String]){
        expirationDate = Date().addingTimeInterval(durationInSecs)
        uuid = UUID().uuidString
        self.value = value
    }
}
