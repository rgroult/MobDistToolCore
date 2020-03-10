//
//  RegistrationError+AbortError.swift
//  App
//
//  Created by Rémi Groult on 10/03/2020.
//

import Foundation
import Vapor

extension RegistrationError:AbortError {    
    var status: HTTPResponseStatus {
        switch self {
        case .emailDomainForbidden:
            return HTTPResponseStatus(statusCode: 400)
        case .invalidEmailFormat:
            return HTTPResponseStatus(statusCode: 400)
        }
    }
}
