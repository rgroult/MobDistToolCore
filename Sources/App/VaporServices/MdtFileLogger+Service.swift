//
//  MdtFileLogger+Service.swift
//  
//
//  Created by Rémi Groult on 30/12/2020.
//

import Vapor

struct MdtFileLoggerKey: StorageKey {
    typealias Value = MdtFileLogger
}

extension Application {
    var mdtLogger: MdtFileLogger? {
        get {
            self.storage[MdtFileLoggerKey.self]
        }
        set {
            self.storage[MdtFileLoggerKey.self] = newValue
        }
    }
}

extension Request {
    var mdtLogger: MdtFileLogger? {
        return application.activityLogger
    }
}
