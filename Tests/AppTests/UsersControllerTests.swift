//
//  UsersControllerTests.swift
//  AppTests
//
//  Created by Remi Groult on 14/03/2019.
//

import Foundation
import Vapor
import XCTest
@testable import App

final class UsersControllerTests: BaseAppTests {
    override func setUp() {
        var env = Environment.xcode
        env.arguments += ["-DautomaticRegistration=false"]
        configure(with: env)
    }
    
    func testRegister() throws{
        let email = "toto@toto.com"
        let registerReq = RegisterDto(email: "toto@toto.com", name: "toto", password: "passwd")
        let registerJSON = try JSONEncoder().encode(registerReq)
        
        let body = registerJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/register", body){ res in
            XCTAssertNotNil(res)
            // let token = res.content.get(String.self, at: "token")
            print(res.content)
            let registerResp = try res.content.decode(UserDto.self).wait()
            XCTAssertEqual(registerResp.email, registerReq.email)
            XCTAssertEqual(registerResp.name, registerReq.name)
            XCTAssertEqual(registerResp.isActivated, false)
            XCTAssertEqual(registerResp.isSystemAdmin, false)
            print(registerResp)
        }
    }
}
