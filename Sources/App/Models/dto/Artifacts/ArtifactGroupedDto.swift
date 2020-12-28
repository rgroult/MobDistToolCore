//
//  ArtifactGrouped.swift
//  App
//
//  Created by Rémi Groult on 12/11/2019.
//

import Foundation
import Vapor
//import Meow

struct ArtifactGroupedDto: Codable {
    let sortIdentifier:String
    let branch:String
    let createdDate:Date
    let version:String
    let artifacts:[ArtifactDto]
}

extension ArtifactGroupedDto: Content {}

extension ArtifactGroupedDto {
    init(from group:ArtifactGrouped){
        sortIdentifier = group.identifier.sortIdentifier
        let isLatestBranch = group.identifier.branch == lastVersionBranchName
        branch = isLatestBranch ? "" : group.identifier.branch
        createdDate = group.createdDate
        version = group.version
        artifacts = group.artifacts.map{ArtifactDto(from: $0)}
    }

    static func sample() -> ArtifactGroupedDto {
        return ArtifactGroupedDto(sortIdentifier:"X.Y.Z",branch:"Master",createdDate:Date(), version:"X.Y.Z", artifacts:[ArtifactDto.sample()])
    }
}
