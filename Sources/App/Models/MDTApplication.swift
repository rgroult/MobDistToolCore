//
//  Application.swift
//  App
//
//  Created by Rémi Groult on 12/02/2019.
//
import Vapor
import Meow
import MongoKitten

 final class MDTApplication: Model/*,ReadableModel */{
    struct PermanentLink2:Codable {
        let applicationUuid:String
        let branch:String
        let artifactName:String
        var expirationDate:Date
        let validity:Int
    }
         /*
         
    struct TokenLink {
        let tokenId:String
        var application:MDTApplication?
        let link:PermanentLink
    }
    struct PermanentLink:Codable {
        let applicationUuid:String
        let branch:String
        let artifactName:String
        let validity:Int
    }*/
    //static let defaultIconPlaceholder = "images/placeholder.jpg"
    //static let collectionName = "MDTApplication"
    var _id = ObjectId()
    var name:String
    var description:String
    var platform:Platform
    var uuid:String
    var base64IconData:String?
    var apiKey:String
    var maxVersionSecretKey:String?
    var adminUsers: [Reference<User>]
    var permanentLinks: [Reference<TokenInfo>]?
    var createdAt:Date
    
    func isAdmin(user:User) -> Bool {
        return user.isSystemAdmin || adminUsers.contains(Reference(to: user))
    }
    
    init(name:String,platform:Platform,adminUser:User, description:String){
        self.name = name
        self.platform = platform
        self.description = description
        self.adminUsers = [Reference(to: adminUser)]
        self.base64IconData = nil
        self.apiKey = UUID().uuidString
        self.uuid = UUID().uuidString
        self.maxVersionSecretKey = nil
        self.permanentLinks = []
        self.createdAt = Date()
    }
    
    func generateIconUrl(externalUrl:URL) -> String? {
        if let base64IconData = base64IconData {
            let hashCode = base64IconData.hashValue
            return externalUrl.appendingPathComponent("\(uuid)/icon").absoluteString + "?h=\(hashCode)" //add hash to manage screenshot update"
        }
        return nil
    }
}
//BsonDbPointer{namespace='MDTUser', id=56d5a8a8f558ddacef0f14b1}

/// Allows `Todo` to be used as a dynamic migration.
//extension User: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
//extension MDTApplication: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
//extension MDTApplication: Parameter { }



