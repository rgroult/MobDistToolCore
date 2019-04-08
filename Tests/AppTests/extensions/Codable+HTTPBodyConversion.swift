//
//  Codable+HTTPBodyConvertion.swift
//  AppTests
//
//  Created by Rémi Groult on 08/04/2019.
//

import Foundation
import Vapor

extension Encodable {
    func convertToHTTPBody() throws -> HTTPBody {
       return try JSONEncoder().encode(self).convertToHTTPBody()
    }
}
