//
//  Artifact.swift
//  App
//
//  Created by Rémi Groult on 27/02/2019.
//

import Vapor
import MeowVapor
import MongoKitten

typealias StorageAccessUrl = String

final class Artifact: Model {
    static let collectionName = "MDTArtifact"
    var _id = ObjectId()
    var application:  Reference<MDTApplication>
    var name:String
    var version:String
    var branch:String
    var uuid:String
    var sortIdentifier:String?
    var metaDataTags:String?
    //file info
    var storageInfos:StorageAccessUrl?
    var filename:String?
    var size:Int?
    var contentType:String?
    
    //var adminUsers: [Data]
    
    init(app:MDTApplication,name:String,version:String,branch:String){
        self.application = Reference(to: app)
        self.name = name
        self.version = version
        self.branch = branch
        self.uuid = UUID().uuidString
        sortIdentifier = nil
        metaDataTags = nil
        storageInfos = nil
        filename = nil
        size = nil
        contentType = nil
    }
    
    func addMetaData(metaData:[String:String]){
        var allTags:[String:String]
        if let existingData = metaDataTags?.convertToData(), let existingTags = try? JSONDecoder().decode([String : String].self,from: existingData)  {
            allTags = existingTags.merging(metaData, uniquingKeysWith: { (_, new) in new})
        }else {
            allTags = metaData
        }
        if let encodedTags = try? JSONEncoder().encode(allTags) {
            metaDataTags = String(data: encodedTags, encoding: .utf8)
        }
    }
}

/// Allows `Todo` to be used as a dynamic migration.
//extension User: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
//extension Artifact: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension Artifact: Parameter { }
