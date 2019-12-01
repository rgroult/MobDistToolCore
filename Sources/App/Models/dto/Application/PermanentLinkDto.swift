//
//  PermanentLink.dto.swift
//  App
//
//  Created by Remi Groult on 01/12/2019.
//

import Foundation
import Vapor

struct PermanentLinkDto: Codable {
    let installUrl:String
    let installPageUrl:String
    let daysValidity:Int
    let branch:String
    let currentVersion:String
    let artifactName:String
}
