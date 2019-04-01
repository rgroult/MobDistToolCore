//
//  ApplicationsTests.swift
//  App
//
//  Created by Remi Groult on 01/04/2019.
//

import Foundation
import Vapor
import XCTest
@testable import App

let appDtoiOS = ApplicationCreateDto(name: "test App iOS", platform: Platform.ios, description: "bla bla", base64IconData: nil, enableMaxVersionCheck:  nil)
let appDtoAndroid = ApplicationCreateDto(name: "test App Android", platform: Platform.android, description: "bla bla", base64IconData: nil, enableMaxVersionCheck:  nil)

final class ApplicationsTests: BaseAppTests {
    func testCreate() throws{
        _ = try register(registerInfo: userToto, inside: app)
        let loginDto = try login(withEmail: userToto.email, password: userToto.password, inside: app)
        let token = loginDto.token
        
        let appCreation = appDtoiOS
        let bodyJSON = try JSONEncoder().encode(appCreation)
        
        let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Applications", body,token:token){ res in
            print(res.content)
            let app = try res.content.decode(ApplicationDto.self).wait()
            XCTAssertTrue(app.description == appDtoiOS.description)
            XCTAssertTrue(app.maxVersionSecretKey == nil)
            XCTAssertTrue(app.name == appDtoiOS.name)
            XCTAssertTrue(app.platform == appDtoiOS.platform)
            XCTAssertNotNil(app.uuid)
            XCTAssertNotNil(app.apiKey)
            XCTAssertTrue(app.adminUsers.first?.email == userToto.email)
            XCTAssertEqual(res.http.status.code , 200)
        }
    }
    
    func testCreateMultiple() throws{
        try testCreate()
        
        //create another user
        _ = try register(registerInfo: userTiti, inside: app)
        let loginDto = try login(withEmail: userTiti.email, password: userTiti.password, inside: app)
        let token = loginDto.token
        
        let appCreation = appDtoAndroid
        let bodyJSON = try JSONEncoder().encode(appCreation)
        
        let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Applications", body,token:token){ res in
            let app = try res.content.decode(ApplicationDto.self).wait()
            XCTAssertNotNil(app.uuid)
            XCTAssertNotNil(app.apiKey)
            XCTAssertEqual(res.http.status.code , 200)
        }
    }
    
    func testCreateTwiceError() throws{
        try testCreate()
        
        //login
        let loginDto = try login(withEmail: userToto.email, password: userToto.password, inside: app)
        let token = loginDto.token
        
        //try to create same app
        let appCreation = appDtoiOS
        let bodyJSON = try JSONEncoder().encode(appCreation)
        
        let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Applications", body,token:token){ res in
            print(res.content)
            XCTAssertEqual(res.http.status.code , 400)
        }
    }
    
    func testSearch() throws {
        
    }
}
