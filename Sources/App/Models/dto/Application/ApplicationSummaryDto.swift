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
    var iconUrl:String?
}

extension ApplicationSummaryDto {
    static func sample() -> ApplicationSummaryDto {
        return ApplicationSummaryDto( name: "Awesome App", platform:.ios ,description:"",uuid:"dsfdsfdsf",iconUrl: nil)
    }
    
    init(from app:MDTApplication){
        name = app.name
        description = app.description
        platform = app.platform
        uuid = app.uuid
    }
    
    func setIconUrl(url:String?) -> ApplicationSummaryDto {
        var result = self
        result.iconUrl = url
        return result
    }
    /*
    mutating func addIconUrl(from app:MDTApplication,externalUrl:String){
        if app.base64IconData != MDTApplication.defaultIconPlaceholder {
            var path = "v2/\(uuid)/icon"
            if !externalUrl.hasSuffix("/") {
                path = "/" + path
            }
            iconUrl = externalUrl + path
        }
    }*/
}

extension ApplicationSummaryDto : Content {}
