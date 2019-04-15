//
//  ArtifactCreateDto.swift
//  App
//
//  Created by Remi Groult on 15/04/2019.
//

import Foundation
import Vapor

struct ArtifactCreateUpdateDto: Codable {
    var branch:String
    var name:String
    var version:String
    var sortIdentifier:String?
    var metaDataTags:[String:String]?
}

extension ArtifactCreateUpdateDto {
    static func sample() -> ArtifactCreateUpdateDto {
        return ArtifactCreateUpdateDto(branch:"master",name:"prod",version:"X.Y.Z",sortIdentifier:nil,metaDataTags:nil)
    }
}

//var branch:String
//var name:String
//var contentType:String
//var filename:String
//var creationDate:String
//var size:Int
//var application:String
//var version:String
//var sortIdentifier:String
//var storageInfos:String
//var metaDataTags:[String:String]
