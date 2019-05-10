//
//  ArtifactError+AbortError.swift
//  App
//
//  Created by Remi Groult on 10/05/2019.
//

import Foundation
import Vapor

extension ArtifactError:AbortError {
    var status: HTTPResponseStatus {
        return HTTPResponseStatus(statusCode: 400)
    }
}



