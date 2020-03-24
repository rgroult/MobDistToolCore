//
//  UpdateUserDto.swift
//  App
//
//  Created by Remi Groult on 10/10/2019.
//

import Foundation
import Vapor

struct UpdateUserDto:Codable {
    var name:String? = nil
    var password:String? = nil
    var currentPassword:String? = nil
    var favoritesApplicationsUUID:[String]? = nil
}

extension UpdateUserDto {
    static func sample() -> UpdateUserDto {
        return UpdateUserDto(name: "John Doe",password:"NeW PaSsw0rD",currentPassword:"pwd",favoritesApplicationsUUID:["XXX_XX__X_X_X"])
    }
}

extension UpdateUserDto: Content {}

struct UpdateUserFullDto:Codable {
    var name:String? = nil
    var password:String? = nil
    var favoritesApplicationsUUID:[String]? = nil
    var isActivated:Bool? = nil
    var isSystemAdmin:Bool? = nil
}

extension UpdateUserFullDto {
    static func sample() -> UpdateUserFullDto {
        return UpdateUserFullDto(name: "John Doe",password:"NeW PaSsw0rD",favoritesApplicationsUUID:["XXX_XX__X_X_X"],isActivated:nil,isSystemAdmin:false)
    }
}

extension UpdateUserFullDto: Content {}
