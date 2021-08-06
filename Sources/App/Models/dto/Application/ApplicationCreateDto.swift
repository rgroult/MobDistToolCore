//
//  CreateApplicationDto.swift
//  App
//
//  Created by Remi Groult on 26/03/2019.
//

import Foundation
import Vapor
//import Meow

struct ApplicationCreateDto: Codable {
    var name:String
    var platform:Platform
    var description:String
    var base64IconData:String?
    var enableMaxVersionCheck:Bool?
}

extension ApplicationCreateDto {
    static func sample() -> ApplicationCreateDto {
        return ApplicationCreateDto( name: "Awesome App", platform:.ios ,description:"",base64IconData:nil,enableMaxVersionCheck:false)
    }
}

extension ApplicationCreateDto : Content {}
