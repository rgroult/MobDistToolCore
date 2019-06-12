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
        let tokenId = try store(info: value, durationInSecs: 2, into: context).wait()
        XCTAssertNotNil(tokenId)
    }
    
    func testCreateAndRetrieveToken() throws {
        let value = ["Hello":"World"]
        let tokenId = try store(info: value, durationInSecs: 2, into: context).wait()
        
        let retrieveValue = try findInfo(with: tokenId, into: context).wait()
        
        XCTAssertEqual(value, retrieveValue)
    }
    
    func testExpiredDuration() throws{
        let value = ["Hello":"World"]
        let tokenId = try store(info: value, durationInSecs: 2, into: context).wait()
        sleep(4)
        let retrieveValue = try findInfo(with: tokenId, into: context).wait()
        XCTAssertNil(retrieveValue)
    }
    
    func testExpiredPurge() throws{
        let value = ["Hello":"World"]
        _ = try store(info: value, durationInSecs: 2, into: context).wait()
        sleep(4)
        var purged = try purgeExpiredTokens(into: context).wait()
        XCTAssertEqual(purged, 1)
        
        purged = try purgeExpiredTokens(into: context).wait()
        XCTAssertEqual(purged, 0)
    }
    
    func testPurgeAll() throws{
        let value = ["Hello":"World"]
        for _ in 0..<100 {
            _ = try store(info: value, durationInSecs: 2, into: context).wait()
        }
        let purged = try purgeAllTokens(into: context).wait()
        XCTAssertEqual(purged, 100)
        
    }
}
