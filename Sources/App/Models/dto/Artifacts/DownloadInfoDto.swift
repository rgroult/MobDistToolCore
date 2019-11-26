//
//  DownloadInfoDto.swift
//  App
//
//  Created by Remi Groult on 14/06/2019.
//

import Foundation
import Vapor


struct DownloadInfoDto: Codable {
    let directLinkUrl:String
    let installUrl:String
    let installPageUrl:String
    let validity:Int
}

extension DownloadInfoDto: Content {}

extension DownloadInfoDto {
    static func sample() -> DownloadInfoDto {
        return DownloadInfoDto(directLinkUrl: "http://mdtHost/XXXXX/artifactFile", installUrl: "http://mdtHost/XXXXX/installArtifact", installPageUrl:"http://mdtHost/XXXXX/installPage",  validity: 3)
    }
}
