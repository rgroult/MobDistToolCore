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

final class Artifact: Model,QueryableModel {
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
    var createdAt:Date
    
    //var adminUsers: [Data]

    func description() -> String{
        return "branch:\(branch),version:\(version),name:\(name),uuid:\(uuid),size:\(size ?? -1),filename:\(filename ?? "[]")"
    }
    
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
        createdAt = Date()
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
    
    func retrieveMetaData() -> [String:String]? {
        if let tagsData = metaDataTags?.convertToData() {
            let decoder = JSONDecoder()
            decoder.dataDecodingStrategy = .custom({ decoder -> Data in
                //decode only String and Int
                // for backward compatibility with MDT V1
                let container = try decoder.singleValueContainer()
                let value:String
                if let v = try? container.decode(String.self) {
                    value  = v
                } else {
                    value = "\(try container.decode(Int.self).description)"
                }
                
                if let data = value.data(using: .utf8) {
                    return data
                }
                else {
                    throw DecodingError.dataCorruptedError(in: container,
                    debugDescription:  "Invalid value \(value)")
                }
            })
            let tags = try? decoder.decode([String:Data].self, from: tagsData)
            return tags?.mapValues({ String(data: $0, encoding: .utf8) ?? "" })
        }
        return nil
    }
}

/// Allows `Todo` to be used as a dynamic migration.
//extension User: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages.
//extension Artifact: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions.
extension Artifact: Parameter { }
