//
//  TokenInfoServiceTests.swift
//  AppTests
//
//  Created by Remi Groult on 11/06/2019.
//

import XCTest
import Vapor
import Meow
@testable import App


final class TokenInfoServiceTests: BaseAppTests {
    func testCreateToken() throws {
        let value = ["Hello":"World"]
        let tokenId = store(info: value, durationInSecs: 2, into: context)
        XCTAssertNotNil(tokenId)
    }
    
    
}
