//
//  PermanentLink.dto.swift
//  App
//
//  Created by Remi Groult on 01/12/2019.
//

import Foundation
import Vapor

struct PermanentLinkDto: Codable {
    let uuid:String
    let installUrl:String
    let installPageUrl:String
    let daysValidity:Int
    let branch:String
    let currentVersion:String?
    let artifactName:String
}


extension PermanentLinkDto {
    
    init(uuid:String, from info:MDTApplication.PermanentLink2,artifact:Artifact?,installUrl:String,installPageUrl:String){
        self.init(uuid:uuid ,installUrl: installUrl, installPageUrl: installPageUrl, daysValidity: info.validity, branch: info.branch, currentVersion: artifact?.version, artifactName: info.artifactName)
    }
}

extension PermanentLinkDto: Content {}
