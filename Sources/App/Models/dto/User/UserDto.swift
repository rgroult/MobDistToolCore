//
//  UserDto.swift
//  App
//
//  Created by Rémi Groult on 14/02/2019.
//

import Foundation
import Vapor

struct UserDto: Codable {
    var email:String
    var name:String
    var isActivated:Bool? = nil
    var isSystemAdmin:Bool? = nil
    var favoritesApplicationsUUID:[String]? = nil
    var administretedApplications:[ApplicationSummaryDto]? = nil
    var createdAt:Date? = nil
    var lastLogin:Date? = nil
    var message:String? = nil
}

extension UserDto {
    static func sample() -> UserDto {
        return UserDto( email: "email@test.com", name: "John Doe",isActivated:nil,isSystemAdmin:nil,favoritesApplicationsUUID:nil,administretedApplications:nil,createdAt:nil,lastLogin:nil,message:nil)
    }
    
    static func create(from user:User, content:ModelVisibility) -> UserDto {
            return UserDto(from: user, content: content)
    }

    private init(from user:User, content:ModelVisibility){
        email = user.email
        name = user.name
        if content == .full {
            isSystemAdmin = user.isSystemAdmin
            isActivated = user.isActivated
            if let appUUID = user.favoritesApplicationsUUID,let data = appUUID.data(using: .utf8) {
                do {
                    favoritesApplicationsUUID = try JSONDecoder().decode([String].self, from: data)
                }catch {}
            }
            
            createdAt = user.createdAt
            lastLogin = user.lastLogin
        }
    }
}

extension UserDto: Content {}
