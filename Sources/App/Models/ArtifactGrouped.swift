//
//  ArtifactGrouped.swift
//  App
//
//  Created by Rémi Groult on 12/11/2019.
//

import Foundation
import Vapor
import Meow

struct ArtifactGrouped: Codable {
    struct Identifier:Codable {
         let sortIdentifier:String
         let branch:String
    }
    let identifier:Identifier
    let createdDate:Date
    let version:String
    let artifacts:[Artifact]
    
    enum CodingKeys: String, CodingKey {
        case identifier = "_id"
        case createdDate = "date"
        case version
        case artifacts
    }
}
