//
//  MaVersionDto.swift
//  App
//
//  Created by Remi Groult on 27/11/2019.
//

import Foundation
import Vapor


struct MaxVersionArtifactDto: Codable {
    let branch:String
    let name:String
    let version:String
    let info:DownloadInfoDto
}

extension MaxVersionArtifactDto: Content {}

extension MaxVersionArtifactDto {
    static func sample() -> MaxVersionArtifactDto {
        return MaxVersionArtifactDto(branch:"master",name:"prod",version:"X.Y.Z",info:DownloadInfoDto.sample())
    }
}
