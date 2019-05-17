//
//  ArtifactDto.swift
//  App
//
//  Created by Remi Groult on 15/04/2019.
//

import Foundation
import Vapor

struct ArtifactDto: Codable {
    var branch:String
    var name:String
    var contentType:String?
   // var creationDate:Date TODO
    var size:Int?
    var version:String
    var sortIdentifier:String?
    var metaDataTags:[String:String]?
}

extension ArtifactDto {
    static func sample() -> ArtifactDto {
        return ArtifactDto(branch:"master",name:"prod",contentType:nil,size:nil,version:"X.Y.Z",sortIdentifier:nil,metaDataTags:nil)
    }
    
    init(from artifact:Artifact, content:ModelVisibility){
        branch = artifact.branch
        name = artifact.name
        contentType = artifact.contentType
        version = artifact.version
        size = artifact.size
        sortIdentifier = artifact.sortIdentifier
        
        if let tagsData = artifact.metaDataTags?.convertToData() {
            let tags = (try? JSONDecoder().decode([String:String].self, from: tagsData))
            metaDataTags = tags
        }
    }
}

extension ArtifactDto: Content {}
