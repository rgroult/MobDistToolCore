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

final class ApplicationsControllerTests: BaseAppTests {
    func testCreate() throws{
        _ = try register(registerInfo: userIOS, inside: app)
        let loginDto = try login(withEmail: userIOS.email, password: userIOS.password, inside: app)
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
            XCTAssertTrue(app.adminUsers.first?.email == userIOS.email)
            XCTAssertEqual(res.http.status.code , 200)
        }
    }
    
    func testCreateMultiple() throws{
        try testCreate()
        
        //create another user
        _ = try register(registerInfo: userANDROID, inside: app)
        let loginDto = try login(withEmail: userANDROID.email, password: userANDROID.password, inside: app)
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
        let loginDto = try login(withEmail: userIOS.email, password: userIOS.password, inside: app)
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
        let loginDto = try login(withEmail: userIOS.email, password: userIOS.password, inside: app)
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
        
        let token = try login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
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
        let token = try login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
        
        let appsResp = try app.clientSyncTest(.GET, "/v2/Applications", nil,["platform":"TOTO"] ,token: token)
        XCTAssertEqual(appsResp.http.status.code , 400)
    }
    
    func testAllApplicationsMultipleUsers() throws {
        try testCreateMultiple()
        
        //login
        let loginDto = try login(withEmail: userIOS.email, password: userIOS.password, inside: app)
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
        let loginDto = try login(withEmail: userIOS.email, password: userIOS.password, inside: app)
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
        let loginDto = try login(withEmail: userANDROID.email, password: userANDROID.password, inside: app)
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
    
    func testDeleteApplication() throws {
        try testCreateMultiple()
        //login
        let token = try login(withEmail: userANDROID.email, password: userANDROID.password, inside: app).token
        
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode([ApplicationSummaryDto].self).wait()
        
        let appFound = apps.first(where:{ $0.name == appDtoAndroid.name})
        XCTAssertNotNil(appFound)
        
        //delete App
        let deleteApp = try app.clientSyncTest(.DELETE, "/v2/Applications/\(appFound!.uuid)",token:token)
        print(deleteApp.content)
        XCTAssertEqual(deleteApp.http.status.code , 200)
        
    }
    func testDeleteApplicationKO() throws {
        try testCreateMultiple()
        //login
        let token = try login(withEmail: userANDROID.email, password: userANDROID.password, inside: app).token
        
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode([ApplicationSummaryDto].self).wait()
        
        let appFound = apps.first(where:{ $0.name == appDtoiOS.name})
        XCTAssertNotNil(appFound)
        
        //delete App
        let deleteApp = try app.clientSyncTest(.DELETE, "/v2/Applications/\(appFound!.uuid)",token:token)
        XCTAssertEqual(deleteApp.http.status.code , 400)
        let errorResp = try deleteApp.content.decode(ErrorDto.self).wait()
        XCTAssertEqual(errorResp.reason , "ApplicationError.notAnApplicationAdministrator")
    }
    
    func testAppDetail() throws {
        try testCreate()
        //login
        let token = try login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
        
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode([ApplicationSummaryDto].self).wait()
        
        let appFound = apps.first
        XCTAssertNotNil(appFound)
        
        //check detail
        let detailResp = try app.clientSyncTest(.GET, "/v2/Applications/\(appFound!.uuid)",token:token)
        print(detailResp.content)
        XCTAssertEqual(detailResp.http.status.code , 200)
        let app = try detailResp.content.decode(ApplicationDto.self).wait()
        XCTAssertEqual(app.adminUsers.count , 1)
        XCTAssertNotNil(app.apiKey)
    }
    
    func testAppDetailNotAdmin() throws {
        try testCreateMultiple()
        
        //login
        let token = try login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
        
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode([ApplicationSummaryDto].self).wait()
        
        //find not admin app
        let appFound = apps.first(where:{ $0.name == appDtoAndroid.name})
        
        //check detail
        let detailResp = try app.clientSyncTest(.GET, "/v2/Applications/\(appFound!.uuid)",token:token)
        let app = try detailResp.content.decode(ApplicationDto.self).wait()
        XCTAssertNil(app.apiKey)
    }
    
    func testAddAdminUser() throws {
        try testCreateMultiple()
        //login
        let token = try login(withEmail: userANDROID.email, password: userANDROID.password, inside: app).token
        
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode([ApplicationSummaryDto].self).wait()
        
        let appFound = apps.first(where:{ $0.name == appDtoAndroid.name})
        XCTAssertNotNil(appFound)
        
        //add admin
        let adminEscaped = userIOS.email.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        let resp = try app.clientSyncTest(.PUT, "/v2/Applications/\(appFound!.uuid)/adminUsers/\(adminEscaped!)",token:token)
        print(resp.content)
        XCTAssertEqual(resp.http.status.code , 200)
        
        //check detail
        let detailResp = try app.clientSyncTest(.GET, "/v2/Applications/\(appFound!.uuid)",token:token)
        XCTAssertEqual(detailResp.http.status.code , 200)
        let app = try detailResp.content.decode(ApplicationDto.self).wait()
        
        XCTAssertEqual(app.adminUsers.count , 2)
        
    }
    func testAddAdminUserInvalid() throws {
        try testCreateMultiple()
        //login
        let token = try login(withEmail: userANDROID.email, password: userANDROID.password, inside: app).token
        
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode([ApplicationSummaryDto].self).wait()
        
        let appFound = apps.first(where:{ $0.name == appDtoAndroid.name})
        XCTAssertNotNil(appFound)
        
        //add invalid admin
        let adminEscaped = "John@Doe.com".addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        let resp = try app.clientSyncTest(.PUT, "/v2/Applications/\(appFound!.uuid)/adminUsers/\(adminEscaped!)",token:token)
        print(resp.content)
        XCTAssertEqual(resp.http.status.code , 400)
        let errorResp = try resp.content.decode(ErrorDto.self).wait()
        XCTAssertEqual(errorResp.reason , "ApplicationError.invalidApplicationAdministrator")
    }
    
    func testAddAdminUserUnAuthorized() throws {
        try testCreateMultiple()
        //login
        let token = try login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
        
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode([ApplicationSummaryDto].self).wait()
        
        let appFound = apps.first(where:{ $0.name == appDtoAndroid.name})
        XCTAssertNotNil(appFound)
        
        //add invalid admin
        let adminEscaped = userIOS.email.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        let resp = try app.clientSyncTest(.PUT, "/v2/Applications/\(appFound!.uuid)/adminUsers/\(adminEscaped!)",token:token)
        print(resp.content)
        XCTAssertEqual(resp.http.status.code , 400)
        let errorResp = try resp.content.decode(ErrorDto.self).wait()
        XCTAssertEqual(errorResp.reason , "ApplicationError.notAnApplicationAdministrator")
    }
    
    func testRemoveAdminUser() throws {
        try testAddAdminUser()
    
        //login
        let token = try login(withEmail: userANDROID.email, password: userANDROID.password, inside: app).token
        
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode([ApplicationSummaryDto].self).wait()
        
        let appFound = apps.first(where:{ $0.name == appDtoAndroid.name})
        XCTAssertNotNil(appFound)
        
        //delete admin
        var adminEscaped = userIOS.email.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        var resp = try app.clientSyncTest(.DELETE, "/v2/Applications/\(appFound!.uuid)/adminUsers/\(adminEscaped!)",token:token)
        print(resp.content)
        XCTAssertEqual(resp.http.status.code , 200)
        
        //check detail
        let detailResp = try app.clientSyncTest(.GET, "/v2/Applications/\(appFound!.uuid)",token:token)
        XCTAssertEqual(detailResp.http.status.code , 200)
        let appDto = try detailResp.content.decode(ApplicationDto.self).wait()
        
        XCTAssertEqual(appDto.adminUsers.count , 1)
        
        //delete last Admin
        adminEscaped = userANDROID.email.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        resp = try app.clientSyncTest(.DELETE, "/v2/Applications/\(appFound!.uuid)/adminUsers/\(adminEscaped!)",token:token)
        print(resp.content)
        XCTAssertEqual(resp.http.status.code , 400)
        let errorResp = try resp.content.decode(ErrorDto.self).wait()
        XCTAssertEqual(errorResp.reason , "ApplicationError.deleteLastApplicationAdministrator")
        
    }
    
    func testRemoveAdminUserInvalid() throws {
        try testAddAdminUser()
        //login
        let token = try login(withEmail: userANDROID.email, password: userANDROID.password, inside: app).token
        
        let application = try findApp(with: appDtoAndroid.name, token: token)
        XCTAssertNotNil(application)
        
        //invalid email
        let adminEscaped = "John@Doe.com".addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        let resp = try app.clientSyncTest(.DELETE, "/v2/Applications/\(application!.uuid)/adminUsers/\(adminEscaped!)",token:token)
        print(resp.content)
        XCTAssertEqual(resp.http.status.code , 400)
        let errorResp = try resp.content.decode(ErrorDto.self).wait()
        XCTAssertEqual(errorResp.reason , "ApplicationError.invalidApplicationAdministrator")
    }
    
    func testRemoveAdminUserUnAuthorized() throws {
        try testCreateMultiple()
        //login
        let token = try login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
        
        let application = try findApp(with: appDtoAndroid.name, token: token)
        XCTAssertNotNil(application)
        
        //invalid email
        let adminEscaped = userANDROID.email.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        let resp = try app.clientSyncTest(.DELETE, "/v2/Applications/\(application!.uuid)/adminUsers/\(adminEscaped!)",token:token)
        print(resp.content)
        XCTAssertEqual(resp.http.status.code , 400)
        let errorResp = try resp.content.decode(ErrorDto.self).wait()
        XCTAssertEqual(errorResp.reason , "ApplicationError.notAnApplicationAdministrator")
    }
    
    private func findApp(with name:String, token:String) throws -> ApplicationSummaryDto?{
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode([ApplicationSummaryDto].self).wait()
        
        return apps.first(where:{ $0.name == name})
    }
    
    private func createAndReturnAppDetail() throws -> (String,ApplicationDto) {
        try testCreate()
        //login
        let token = try login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
        
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode([ApplicationSummaryDto].self).wait()
        
        let appFound = apps.first
        
        //check detail
        let detailResp = try app.clientSyncTest(.GET, "/v2/Applications/\(appFound!.uuid)",token:token)
        print(detailResp.content)
        XCTAssertEqual(detailResp.http.status.code , 200)
        let appDetail = try detailResp.content.decode(ApplicationDto.self).wait()
        
        return (token,appDetail)
    }
    
    func testRetrieveVersion() throws {
        let (token,appDetail) = try createAndReturnAppDetail()
        
        let fileData = try ArtifactsContollerTests.fileData(name: "calculator", ext: "ipa")
        _ = try ArtifactsContollerTests.uploadArtifactSuccess(contentFile: fileData, apiKey: appDetail.apiKey!, branch: "master", version: "1.2.3", name: "prod", contentType:ipaContentType, inside: app)
        
        let allVersions = try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/versions",token:token)
        let versions = try allVersions.content.decode([ArtifactDto].self).wait()
        XCTAssertEqual(versions.count, 1)
        XCTAssertEqual(versions.first?.branch, "master")
        XCTAssertEqual(versions.first?.version,"1.2.3")
        XCTAssertEqual(versions.first?.name,"prod")
       // app/{appId}/versions?pageIndex=1&limitPerPage=30&branch=master'
    }
    
    func uploadArtifact(branches:[String], numberPerBranches:Int,apiKey:String) throws {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 3
        
        for branch in branches {
            for idx in 0..<numberPerBranches {
                let fileData = try ArtifactsContollerTests.fileData(name: "calculator", ext: "ipa")
                let version = formatter.string(from: NSNumber(value: idx))
                _ = try ArtifactsContollerTests.uploadArtifactSuccess(contentFile: fileData, apiKey: apiKey, branch: branch, version: "1.2.\(version!)", name: "prod", contentType:ipaContentType, inside: app)
            }
        }
    }
    
    func testRetrieveVersions() throws {
        let (token,appDetail) = try createAndReturnAppDetail()
        try uploadArtifact(branches: ["master"], numberPerBranches: 50, apiKey: appDetail.apiKey!)
        /*
        for idx in 0..<50 {
            let fileData = try ArtifactsContollerTests.fileData(name: "calculator", ext: "ipa")
            _ = try ArtifactsContollerTests.uploadArtifactSuccess(contentFile: fileData, apiKey: appDetail.apiKey!, branch: "master", version: "1.2.\(idx)", name: "prod", contentType:ipaContentType, inside: app)
        }*/
        
        let allVersions = try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/versions",token:token)
        let versions = try allVersions.content.decode([ArtifactDto].self).wait()
        XCTAssertEqual(versions.count, 50)
        // app/{appId}/versions?pageIndex=1&limitPerPage=30&branch=master'
    }
    
    func testRetrieveVersionsByPages() throws {
        let (token,appDetail) = try createAndReturnAppDetail()
        try uploadArtifact(branches: ["master"], numberPerBranches: 20, apiKey: appDetail.apiKey!)
        
        var allVersions = try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/versions?pageIndex=0&limitPerPage=15",token:token)
        var versions = try allVersions.content.decode([ArtifactDto].self).wait()
        XCTAssertEqual(versions.count, 15)
        XCTAssertEqual(versions.first?.version, "1.2.000")
        
        allVersions = try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/versions?pageIndex=1&limitPerPage=15",token:token)
        versions = try allVersions.content.decode([ArtifactDto].self).wait()
        XCTAssertEqual(versions.count, 5)
        XCTAssertEqual(versions.first?.version, "1.2.015")
        
        allVersions = try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/versions?pageIndex=2&limitPerPage=15",token:token)
        versions = try allVersions.content.decode([ArtifactDto].self).wait()
        XCTAssertEqual(versions.count, 0)
    }
    
    func testRetrieveVersionsByBranch() throws {
        let (token,appDetail) = try createAndReturnAppDetail()
        let branches = ["master","dev","release"]
        try uploadArtifact(branches: branches , numberPerBranches: 10, apiKey: appDetail.apiKey!)
        
        let allVersions = try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/versions",token:token)
        let versions = try allVersions.content.decode([ArtifactDto].self).wait()
        XCTAssertEqual(versions.count, 30)
        
        for branch in branches {
            let allVersions = try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/versions?branch=\(branch)",token:token)
            let versions = try allVersions.content.decode([ArtifactDto].self).wait()
            XCTAssertEqual(versions.count, 10)
            for version in versions {
                XCTAssertEqual(version.branch, branch)
            }
            XCTAssertEqual(versions.last?.version, "1.2.009")
        }
    }
}

extension ApplicationsControllerTests {
    class func createApp(with info:ApplicationCreateDto, inside app:Application,token:String?) throws -> ApplicationDto {
        let body = try info.convertToHTTPBody()
        let result = try app.clientSyncTest(.POST, "/v2/Applications" , body,token:token)
        print(result.content)
        return try result.content.decode(ApplicationDto.self).wait()
    }
}
