//
//  ApplicationUpdateDto.swift
//  App
//
//  Created by Remi Groult on 26/03/2019.
//

import Foundation
import Vapor
//import Meow

struct ApplicationUpdateDto: Codable,Content {
    var name:String?
    var description:String?
    var maxVersionCheckEnabled:Bool?
    var base64IconData:String?
}

extension ApplicationUpdateDto {
    init(maxVersion:Bool?,iconData:String?){
        name = nil
        description = nil
        self.maxVersionCheckEnabled = maxVersion
        self.base64IconData = iconData
    }
}


extension ApplicationUpdateDto {
    static func sample() -> ApplicationUpdateDto {
        return ApplicationUpdateDto( name: "Awesome App", description:"",maxVersionCheckEnabled:nil, base64IconData:nil)
    }
}
