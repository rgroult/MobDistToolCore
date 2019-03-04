//
//  SMTP+ServiceType.swift
//  App
//
//  Created by Remi Groult on 04/03/2019.
//

import SwiftSMTP
import Vapor

extension SMTP: ServiceType {
    
    public static func makeService(for container: Container) throws -> SMTP {
        throw "Unable to make empty service"
    }
}
