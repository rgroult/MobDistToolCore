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

    /*var reason:String {
        return "\(self)"
    }*/
    
    
   /* func toAbortError() -> AbortError {
        switch self {
        case .alreadyExist:
            return Abort(AbortError)
        case .fieldInvalid:
        case .invalidLoginOrPassword:
        case .notFound:
        }
    }*/
}
