//
//  ForgotPasswordDto.swift
//  App
//
//  Created by Rémi Groult on 14/02/2019.
//

import Foundation
import Vapor

struct ForgotPasswordDto: Codable {
    var email:String
}

extension ForgotPasswordDto : Content {}
