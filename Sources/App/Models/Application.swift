//
//  Application.swift
//  App
//
//  Created by Rémi Groult on 12/02/2019.
//
import Vapor
import MeowVapor
import MongoKitten

final class MDTApplication2: Model {
    static let collectionName = "MDTApplication2"
    var _id = ObjectId()
    var name:String
    var adminUsers: Array<Reference<User>>?
}
extension MDTApplication2: Content { }

 final class MDTApplication: Model {
   /*struct DBRef:Codable {
        var ref:String
        var id = ObjectId()
        var db:String
    }*/
   struct BsonDbPointer: Codable {
        var namespace: String
        var id: ObjectId
    }
    static let collectionName = "MDTApplication"
    var _id = ObjectId()
    var name:String
    //var adminUsers:  [Reference<User>]
    var adminUsers: [Reference<User>]
}
//BsonDbPointer{namespace='MDTUser', id=56d5a8a8f558ddacef0f14b1}

/// Allows `Todo` to be used as a dynamic migration.
//extension User: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
extension MDTApplication: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension MDTApplication: Parameter { }


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
