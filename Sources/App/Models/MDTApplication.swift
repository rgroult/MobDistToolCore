//
//  Application.swift
//  App
//
//  Created by Rémi Groult on 12/02/2019.
//
import Vapor
import MeowVapor
import MongoKitten

 final class MDTApplication: Model {
    //static let collectionName = "MDTApplication"
    var _id = ObjectId()
    var name:String
    var description:String
    var platform:Platform
    var uuid:String
    var base64IconData:String
    var apiKey:String
    var maxVersionSecretKey:String?
    var adminUsers: [Reference<User>]
    
    func isAdmin(user:User) -> Bool {
        return user.isSystemAdmin || adminUsers.contains(Reference(to: user))
    }
}
//BsonDbPointer{namespace='MDTUser', id=56d5a8a8f558ddacef0f14b1}

/// Allows `Todo` to be used as a dynamic migration.
//extension User: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
//extension MDTApplication: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
//extension MDTApplication: Parameter { }


final class Artifact: Model {
    static let collectionName = "MDTArtifact"
    var _id = ObjectId()
    var name:String
    var application:  Reference<MDTApplication>
    //var adminUsers: [Data]
}

/// Allows `Todo` to be used as a dynamic migration.
//extension User: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension Artifact: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension Artifact: Parameter { }
