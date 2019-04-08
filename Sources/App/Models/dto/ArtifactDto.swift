//
//  ArtifactDto.swift
//  App
//
//  Created by Rémi Groult on 08/04/2019.
//

import Foundation
import Vapor

struct ArtifactDto: Codable {
}

extension ArtifactDto {
    static func sample() -> ArtifactDto {
        return ArtifactDto()
    }
}

extension ArtifactDto: Content {}
