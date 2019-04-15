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
    var creationDate:Date
    var size:Int?
    var version:String
    var sortIdentifier:String?
    var metaDataTags:[String:String]?
}

extension ArtifactDto {
    static func sample() -> ArtifactDto {
        return ArtifactDto(branch:"master",name:"prod",contentType:nil,creationDate:Date(),size:nil,version:"X.Y.Z",sortIdentifier:nil,metaDataTags:nil)
    }
}

extension ArtifactDto: Content {}
