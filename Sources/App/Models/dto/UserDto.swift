//
//  UserDto.swift
//  App
//
//  Created by Rémi Groult on 14/02/2019.
//

import Foundation

struct UserDto: Codable {
    var email:String
    var name:String
    var isActivated:Bool
}
