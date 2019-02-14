//
//  RegisterMessage.swift
//  App
//
//  Created by Rémi Groult on 14/02/2019.
//

import Foundation

struct RegisterDto: Codable {
    var email:String
    var name:String
    var password:String
}
