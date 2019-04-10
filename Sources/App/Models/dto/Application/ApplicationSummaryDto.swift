//
//  ApplicationSummaryDto.swift
//  App
//
//  Created by Rémi Groult on 09/04/2019.
//

import Foundation
import Vapor

struct ApplicationSummaryDto: Codable {
    var name:String
    var platform:Platform
    var description:String
    var uuid:String
}

extension ApplicationSummaryDto {
    static func sample() -> ApplicationSummaryDto {
        return ApplicationSummaryDto( name: "Awesome App", platform:.ios ,description:"",uuid:"dsfdsfdsf")
    }
    
    init(from app:MDTApplication){
        name = app.name
        description = app.description
        platform = app.platform
        uuid = app.uuid
    }
}

extension ApplicationSummaryDto : Content {}
