//
//  PermanentLinkCreateDto.swift
//  App
//
//  Created by Remi Groult on 17/12/2019.
//

import Foundation
import Vapor

struct PermanentLinkCreateDto: Codable {
    let daysValidity:Int
    let branch:String
    let artifactName:String
}
extension PermanentLinkCreateDto: Content {}
