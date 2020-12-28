//
//  Users.swift
//  App
//
//  Created by Rémi Groult on 12/02/2019.
//

import Vapor
import MongoKitten
import Meow
import JWTAuth

final class User: BaseModel,ReadableModel {
    static let collectionName = "MDTUser"
    var _id = ObjectId()
    var email:String
    var name:String
    var salt:String
    var password:String
    var isSystemAdmin:Bool
    var isActivated:Bool
    var activationToken:String?
    var lastLogin:Date?
    var createdAt:Date
    var favoritesApplicationsUUID:String?
    
     init(email:String, name:String){
        self.email = email
        self.name = name
        salt = ""
        password = ""
        isSystemAdmin = false
        isActivated = false
        activationToken = nil
        lastLogin = nil
        createdAt = Date()
        favoritesApplicationsUUID = nil
    }
}

extension User {
    class func anonymous() -> User {
        return User(email: "anonymous@localhost.com", name: "Anonymous User")
    }
}

//extension User {
//    convenience init(email:String, name:String){
//        self.init(email:email,name:name,salt:"",password:"",isSystemAdmin:false,isActivated:false,activationToken:nil,createdAt: Date(),favoritesApplicationsUUID:nil)
//      /*  */
//    }
//}

/// Allows `Todo` to be used as a dynamic migration.
//extension User: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
//extension User: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
//extension User: Parameter { }
/*
extension UserDto: JWTAuthenticatable {
    
    static func authenticate(using data: LosslessDataConvertible, signers: JWTSignerRepository, on worker: Container) -> EventLoopFuture<UserDto?> {
        return Future(nil)
    }
    
    
}*/
