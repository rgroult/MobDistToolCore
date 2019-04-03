//
//  ApplicationsError+AbortError.swift
//  App
//
//  Created by Remi Groult on 03/04/2019.
//

import Foundation
import Vapor

extension ApplicationError:AbortError {
    var status: HTTPResponseStatus {
        return HTTPResponseStatus(statusCode: 400)
    }
}

