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
            let errorResp = try res.content.decode(ErrorDto.self).wait()
            XCTAssertTrue(errorResp.reason == "ApplicationError.alreadyExist")
        }
    }
    
    func testAllApplications() throws {
        try testCreate()
        
        //login
        let loginDto = try login(withEmail: userToto.email, password: userToto.password, inside: app)
        let token = loginDto.token
        
        try app.clientTest(.GET, "/v2/Applications",token:token){ res in
            print(res.content)
            XCTAssertEqual(res.http.status.code , 200)
            let apps = try res.content.decode([ApplicationSummaryDto].self).wait()
            XCTAssertTrue(apps.count == 1)
            let firstApp = apps.first
            XCTAssertEqual(firstApp?.name, appDtoiOS.name)
            XCTAssertEqual(firstApp?.platform, appDtoiOS.platform)
            XCTAssertEqual(firstApp?.description, appDtoiOS.description)
        }
    }
    
    func testFilterApplications() throws {
        try testCreateMultiple()
        
        let token = try login(withEmail: userToto.email, password: userToto.password, inside: app).token
        //find iOs App
        let appsResp = try app.clientSyncTest(.GET, "/v2/Applications", nil,["platform":Platform.ios.rawValue] ,token: token)
        XCTAssertEqual(appsResp.http.status.code , 200)
        let apps = try appsResp.content.decode([ApplicationSummaryDto].self).wait()
        XCTAssertEqual(apps.count,1)
        
        //find Android App
        let AndroidApps = try app.clientSyncTest(.GET, "/v2/Applications", nil,["platform":Platform.ios.rawValue] ,token: token).content.decode([ApplicationSummaryDto].self).wait()
         XCTAssertEqual(AndroidApps.count,1)
    }
    
    func testFilterApplicationsBadPlatform() throws {
        try testCreate()
        let token = try login(withEmail: userToto.email, password: userToto.password, inside: app).token
        
        let appsResp = try app.clientSyncTest(.GET, "/v2/Applications", nil,["platform":"TOTO"] ,token: token)
        XCTAssertEqual(appsResp.http.status.code , 400)
    }
    
    func testAllApplicationsMultipleUsers() throws {
        try testCreateMultiple()
        
        //login
        let loginDto = try login(withEmail: userToto.email, password: userToto.password, inside: app)
        let token = loginDto.token
        
        try app.clientTest(.GET, "/v2/Applications",token:token){ res in
            print(res.content)
            XCTAssertEqual(res.http.status.code , 200)
            let apps = try res.content.decode([ApplicationSummaryDto].self).wait()
            XCTAssertTrue(apps.count == 2)
           /* apps.forEach({ app in
                if app.adminUsers.contains(where: { $0.email == userToto.email }) {
                    XCTAssertNotNil(app.apiKey)
                }else {
                    XCTAssertNil(app.apiKey)
                }
            })*/
        }
    }
    
    func testUpdateApplication() throws {
        try testCreate()
        
        //login
        let loginDto = try login(withEmail: userToto.email, password: userToto.password, inside: app)
        let token = loginDto.token
        
        try app.clientTest(.GET, "/v2/Applications",token:token){ res in
            let apps = try res.content.decode([ApplicationSummaryDto].self).wait()
            let firstApp = apps.first
            
            let uuid = firstApp?.uuid
             XCTAssertNotNil(uuid)
            
            let updateDto = ApplicationUpdateDto(name: "NewName", description: "New description", maxVersionCheckEnabled: true,base64IconData: nil)
            
            let body = try updateDto.convertToHTTPBody()
            try app.clientTest(.PUT, "/v2/Applications/\(uuid!)", body,token:token){ res in
                print(res.content)
                XCTAssertEqual(res.http.status.code , 200)
                
                let app = try res.content.decode(ApplicationDto.self).wait()
                XCTAssertEqual(app.name, updateDto.name)
                XCTAssertEqual(app.description, updateDto.description)
                XCTAssertNotNil(app.apiKey)
            }
        }
    }
    
    func testUpdateApplicationNotAdmin() throws {
       try testCreateMultiple()
        
        //login
        let loginDto = try login(withEmail: userTiti.email, password: userTiti.password, inside: app)
        let token = loginDto.token
        
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode([ApplicationSummaryDto].self).wait()
        
        //find not admin app
        let appFound = apps.first(where:{ $0.name != appDtoAndroid.name})
        let uuid = appFound?.uuid
        XCTAssertNotNil(uuid)
        
        let updateDto = ApplicationUpdateDto(name: "NewName", description: "New description", maxVersionCheckEnabled: false,base64IconData: nil)
       // let bodyJSON = try JSONEncoder().encode(updateDto)
        let body = try updateDto.convertToHTTPBody()
        
        //try to update not administrated App
        let updateResp = try app.clientSyncTest(.PUT, "/v2/Applications/\(uuid!)",body,token:token)
        print(updateResp.content)
        XCTAssertEqual(updateResp.http.status.code , 400)
    }
}

extension ApplicationsTests {
}
