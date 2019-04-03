//
//  UserError+AbortError.swift
//  App
//
//  Created by Rémi Groult on 18/03/2019.
//

import Foundation
import Vapor

extension UserError:AbortError {
    var status: HTTPResponseStatus {
        return HTTPResponseStatus(statusCode: 400)
    }
}
