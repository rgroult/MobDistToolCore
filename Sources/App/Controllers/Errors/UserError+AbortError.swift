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
        switch self {
        case .userNotAdministrator:
            return HTTPResponseStatus(statusCode: 401)
        default:
            return HTTPResponseStatus(statusCode: 400)
        }
    }
}
