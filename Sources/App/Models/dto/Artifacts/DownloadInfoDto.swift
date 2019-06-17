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
    let validity:Int
}
extension DownloadInfoDto: Content {}
