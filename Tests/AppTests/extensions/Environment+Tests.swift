//
//  Environment+Tests.swift
//  AppTests
//
//  Created by Rémi Groult on 22/02/2019.
//

import XCTest
import Vapor


extension Environment {
    static var xcode: Environment {
        return .init(name: "xcode", arguments:  ["xcode"])
       // return .init(name: "xcode", isRelease: false, arguments: ["xcode"])
    }
}
