//
//  ApplicationsTests.swift
//  App
//
//  Created by Remi Groult on 01/04/2019.
//

import Foundation
import Vapor
import XCTest
//import Pagination
@testable import App

let appDtoiOS = ApplicationCreateDto(name: "testAppiOS", platform: Platform.ios, description: "bla bla", base64IconData: nil, enableMaxVersionCheck:  nil)
let appDtoAndroid = ApplicationCreateDto(name: "test App Android", platform: Platform.android, description: "bla bla", base64IconData: nil, enableMaxVersionCheck:  nil)

 let base64EncodedData = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAnCAYAAABuf0pMAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAACXBIWXMAAAsTAAALEwEAmpwYAAADSGlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNS40LjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIgogICAgICAgICAgICB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyI+CiAgICAgICAgIDx4bXA6TW9kaWZ5RGF0ZT4yMDE2LTAyLTI0VDIyOjAyOjAyPC94bXA6TW9kaWZ5RGF0ZT4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5QaXhlbG1hdG9yIDMuNC4yPC94bXA6Q3JlYXRvclRvb2w+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiAgICAgICAgIDx0aWZmOlJlc29sdXRpb25Vbml0PjI8L3RpZmY6UmVzb2x1dGlvblVuaXQ+CiAgICAgICAgIDx0aWZmOkNvbXByZXNzaW9uPjU8L3RpZmY6Q29tcHJlc3Npb24+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj44MDI8L2V4aWY6UGl4ZWxYRGltZW5zaW9uPgogICAgICAgICA8ZXhpZjpDb2xvclNwYWNlPjE8L2V4aWY6Q29sb3JTcGFjZT4KICAgICAgICAgPGV4aWY6UGl4ZWxZRGltZW5zaW9uPjk4MzwvZXhpZjpQaXhlbFlE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"

final class ApplicationsControllerTests: BaseAppTests {
    func testCreate() throws{
        try createApplication(appData: appDtoiOS)
    }
    
    private func createApplication(appData:ApplicationCreateDto) throws{
        _ = try register(registerInfo: userIOS, inside: app)
        let loginDto = try login(withEmail: userIOS.email, password: userIOS.password, inside: app)
        let token = loginDto.token
        
        let appCreation = appData
        let bodyJSON = try JSONEncoder().encode(appCreation)
        
        //let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Applications", appData,token:token){ res in
           // print(res.content)
            let app = try res.content.decode(ApplicationDto.self)
            XCTAssertTrue(app.description == appDtoiOS.description)
            if appCreation.enableMaxVersionCheck == true {
                XCTAssertTrue(app.maxVersionSecretKey != nil)
            }else {
                XCTAssertTrue(app.maxVersionSecretKey == nil)
            }
            
            XCTAssertTrue(app.name == appCreation.name)
            XCTAssertTrue(app.platform == appCreation.platform)
            XCTAssertNotNil(app.uuid)
            XCTAssertNotNil(app.apiKey)
            if let _ = appData.base64IconData {
                XCTAssertNotNil(app.iconUrl)
            }else {
                XCTAssertNil(app.iconUrl)
            }
            XCTAssertTrue(app.adminUsers.first?.email == userIOS.email)
            XCTAssertEqual(res.status.code , 200)
        }
    }
    
    func testCreateMultiple() throws{
        try testCreate()
        
        //create another user
        _ = try register(registerInfo: userANDROID, inside: app)
        let loginDto = try login(withEmail: userANDROID.email, password: userANDROID.password, inside: app)
        let token = loginDto.token
        
        let appCreation = appDtoAndroid
        //let bodyJSON = try JSONEncoder().encode(appCreation)
        
        //let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Applications", appCreation,token:token){ res in
            let app = try res.content.decode(ApplicationDto.self)
            XCTAssertNotNil(app.uuid)
            XCTAssertNotNil(app.apiKey)
            XCTAssertNil(app.iconUrl)
            XCTAssertEqual(res.status.code , 200)
        }
    }
    
    func testCreateTwiceError() throws{
        try testCreate()
        
        //login
        let loginDto = try login(withEmail: userIOS.email, password: userIOS.password, inside: app)
        let token = loginDto.token
        
        //try to create same app
        let appCreation = appDtoiOS
       // let bodyJSON = try JSONEncoder().encode(appCreation)
        
        //let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Applications", appCreation,token:token){ res in
            print(res.content)
            XCTAssertEqual(res.status.code , 400)
            let errorResp = try res.content.decode(ErrorDto.self)
            XCTAssertTrue(errorResp.reason == "ApplicationError.alreadyExist")
        }
    }
    
    func testAllApplications() throws {
        try testCreate()
        
        //login
        let loginDto = try login(withEmail: userIOS.email, password: userIOS.password, inside: app)
        let token = loginDto.token
        
        try app.clientTest(.GET, "/v2/Applications", token:token){ res in
            print(res.content)
            XCTAssertEqual(res.status.code , 200)
            let pageApps = try res.content.decode(Paginated<ApplicationSummaryDto>.self)
            XCTAssertEqual(pageApps.data.count , 1)
            XCTAssertEqual(pageApps.page.data.total , 1)
            let firstApp = pageApps.data.first
            XCTAssertEqual(firstApp?.name, appDtoiOS.name)
            XCTAssertEqual(firstApp?.platform, appDtoiOS.platform)
            XCTAssertEqual(firstApp?.description, appDtoiOS.description)
        }
    }
    
    func testFilterApplications() throws {
        try testCreateMultiple()
        
        let token = try login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
        //find iOs App
        let appsResp = try app.clientSyncTest(.GET, "/v2/Applications",["platform":Platform.ios.rawValue] ,token: token)
        XCTAssertEqual(appsResp.status.code , 200)
        let pageApps = try appsResp.content.decode(Paginated<ApplicationSummaryDto>.self)
        XCTAssertEqual(pageApps.data.count , 1)
        XCTAssertEqual(pageApps.page.data.total , 1)
        
        //find Android App
        try app.clientTest(.GET, "/v2/Applications", ["platform":Platform.android.rawValue], token: token){ res in
            let AndroidApps = try res.content.decode(Paginated<ApplicationSummaryDto>.self)
            XCTAssertEqual(AndroidApps.data.count , 1)
            XCTAssertEqual(AndroidApps.page.data.total , 1)
        }
        /*
        let AndroidApps = try app.clientSyncTest(.GET, "/v2/Applications", nil,["platform":Platform.ios.rawValue] ,token: token).content.decode(Paginated<ApplicationSummaryDto>.self).wait()
        XCTAssertEqual(AndroidApps.data.count , 1)
        XCTAssertEqual(AndroidApps.page.data.total , 1)*/
    }
    
    func testFilterApplicationsBadPlatform() throws {
        try testCreate()
        let token = try login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
        
        try app.clientTest(.GET, "/v2/Applications",["platform":"TOTO"] ,token: token) { res in
            XCTAssertEqual(res.status.code , 400)
        }
       
    }
    
    func testAllApplicationsMultipleUsers() throws {
        try testCreateMultiple()
        
        //login
        let loginDto = try login(withEmail: userIOS.email, password: userIOS.password, inside: app)
        let token = loginDto.token
        
        try app.clientTest(.GET, "/v2/Applications",token:token){ res in
            print(res.content)
            XCTAssertEqual(res.status.code , 200)
            let apps = try res.content.decode(Paginated<ApplicationSummaryDto>.self)
            XCTAssertTrue(apps.page.data.total == 2)
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
        
        let appResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try appResp.content.decode(Paginated<ApplicationSummaryDto>.self)
        let firstApp = apps.data.first
        
        let uuid = firstApp?.uuid
        XCTAssertNotNil(uuid)
        
        //update
        var updateDto = ApplicationUpdateDto(name: "NewName", description: "New description", maxVersionCheckEnabled: true,base64IconData:  "data:image/png;base64,\(base64EncodedData)")
        
        //var body = try updateDto.convertToHTTPBody()
        
        var updateResp = try app.clientSyncTest(.PUT, "/v2/Applications/\(uuid!)", updateDto,token:token)
        XCTAssertEqual(updateResp.status.code , 200)
        var updatedApp = try updateResp.content.decode(ApplicationDto.self)
        
        XCTAssertTrue(updatedApp.iconUrl?.contains("/v2/Applications/\(uuid!)/icon") ?? false )
        XCTAssertEqual(updatedApp.name, updateDto.name)
        XCTAssertEqual(updatedApp.description, updateDto.description)
        XCTAssertNotNil(updatedApp.apiKey)
        XCTAssertNotNil(updatedApp.maxVersionSecretKey)
        //check icon Url content
        let iconApp = try app.clientSyncTest(.GET, updatedApp.iconUrl!, isAbsoluteUrl:true)
        XCTAssertEqual(iconApp.status.code , 200)
        
        //update 2
        updateDto = ApplicationUpdateDto(name: "NewName 2", description: "bla bla", maxVersionCheckEnabled: false,base64IconData:"")
        
        //body = try updateDto.convertToHTTPBody()
        
        updateResp = try app.clientSyncTest(.PUT, "/v2/Applications/\(uuid!)", updateDto,token:token)
        XCTAssertEqual(updateResp.status.code , 200)
        updatedApp = try updateResp.content.decode(ApplicationDto.self)
        
        XCTAssertNil(updatedApp.iconUrl)
        XCTAssertEqual(updatedApp.name, updateDto.name)
        XCTAssertEqual(updatedApp.description, updateDto.description)
        XCTAssertNotNil(updatedApp.apiKey)
        XCTAssertNil(updatedApp.maxVersionSecretKey)
        
        /*
        try app.clientTest(.GET, "/v2/Applications",token:token){ res in
            let apps = try res.content.decode(Paginated<ApplicationSummaryDto>.self).wait()
            let firstApp = apps.data.first
            
            let uuid = firstApp?.uuid
             XCTAssertNotNil(uuid)
            
            let updateDto = ApplicationUpdateDto(name: "NewName", description: "New description", maxVersionCheckEnabled: true,base64IconData:  "data:image/png;base64,\(base64EncodedData)")
            
            let body = try updateDto.convertToHTTPBody()
            try app.clientTest(.PUT, "/v2/Applications/\(uuid!)", body,token:token){ res in
                print(res.content)
                XCTAssertEqual(res.http.status.code , 200)
                
                let app = try res.content.decode(ApplicationDto.self).wait()
                XCTAssertTrue(app.iconUrl?.contains("/v2/Applications/\(uuid!)/icon") ?? false )
                XCTAssertEqual(app.name, updateDto.name)
                XCTAssertEqual(app.description, updateDto.description)
                XCTAssertNotNil(app.apiKey)
                XCTAssertNotNil(app.maxVersionSecretKey)
                
            }
        }*/
    }
    
    func findApp(token:String, name:String) throws -> ApplicationSummaryDto?{
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode(Paginated<ApplicationSummaryDto>.self)
        
        //find not admin app
        return apps.data.first(where:{ $0.name == name})
    }
    
    func testUpdateApplicationNotAdmin() throws {
       try testCreateMultiple()
        
        //login
        let loginDto = try login(withEmail: userANDROID.email, password: userANDROID.password, inside: app)
        let token = loginDto.token
        
        let appFound = try findApp(token: token, name: appDtoiOS.name/*appDtoAndroid.name*/)
        
        let uuid = appFound?.uuid
        XCTAssertNotNil(uuid)
        
        let updateDto = ApplicationUpdateDto(name: "NewName", description: "New description", maxVersionCheckEnabled: false,base64IconData: nil)
       // let bodyJSON = try JSONEncoder().encode(updateDto)
        let body = try updateDto.convertToHTTPBody()
        
        //try to update not administrated App
        let updateResp = try app.clientSyncTest(.PUT, "/v2/Applications/\(uuid!)",updateDto,token:token)
        print(updateResp.content)
        XCTAssertEqual(updateResp.status.code , 400)
    }
    
    func testDeleteApplication() throws {
        try testCreateMultiple()
        //login
        let token = try login(withEmail: userANDROID.email, password: userANDROID.password, inside: app).token
        
        let appFound = try findApp(token: token, name: appDtoAndroid.name)
        /*
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode(Paginated<ApplicationSummaryDto>.self).wait()
        
        let appFound = apps.data.first(where:{ $0.name == appDtoAndroid.name})*/
        XCTAssertNotNil(appFound)
        
        //delete App
        let deleteApp = try app.clientSyncTest(.DELETE, "/v2/Applications/\(appFound!.uuid)",token:token)
        print(deleteApp.content)
        XCTAssertEqual(deleteApp.status.code , 200)
        
    }


    func testDeleteApplicationWithArtifacts() throws {
        try testCreateMultiple()
        //count all artifacts
        XCTAssertEqual(try context.collection(for: MDTApplication.self).count(where: []).wait(), 2)
        XCTAssertEqual(try context.collection(for: Artifact.self).count(where: []).wait(), 0)

        //login
        var token = try login(withEmail: userANDROID.email, password: userANDROID.password, inside: app).token

        let appAndroidFound = try findApp(token: token, name: appDtoAndroid.name)
        //check detail
        var appDetail = try returnAppDetail(uuid: appAndroidFound!.uuid, token: token)

        let branches = ["master","dev","release"]
        try uploadArtifact(branches: branches , numberPerBranches: 5, apiKey: appDetail.apiKey!,mediaType:apkContentType)
        //number of artifact
        XCTAssertEqual(try context.collection(for: Artifact.self).count(where: []).wait(), 15)


        token = try login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
        let appiOSFound = try findApp(token: token, name: appDtoiOS.name)
        appDetail = try returnAppDetail(uuid: appiOSFound!.uuid, token: token)
        try uploadArtifact(branches: branches , numberPerBranches: 4, apiKey: appDetail.apiKey!,mediaType:ipaContentType)
        //number of artifact
        XCTAssertEqual(try context.collection(for: Artifact.self).count(where: []).wait(), 27)

        token = try login(withEmail: userANDROID.email, password: userANDROID.password, inside: app).token
        //delete App
        let deleteApp = try app.clientSyncTest(.DELETE, "/v2/Applications/\(appAndroidFound!.uuid)",token:token)
        XCTAssertEqual(deleteApp.status.code , 200)

        //count all artifacts
        XCTAssertEqual(try context.collection(for: MDTApplication.self).count(where: []).wait(), 1)
        XCTAssertEqual(try context.collection(for: Artifact.self).count(where: []).wait(), 12)
    }

    func testDeleteApplicationKO() throws {
        try testCreateMultiple()
        //login
        let token = try login(withEmail: userANDROID.email, password: userANDROID.password, inside: app).token
        
        let appFound = try findApp(token: token, name: appDtoiOS.name)
        /*
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode(Paginated<ApplicationSummaryDto>.self).wait()
        
        let appFound = apps.data.first(where:{ $0.name == appDtoiOS.name})*/
        XCTAssertNotNil(appFound)
        
        //delete App
        let deleteApp = try app.clientSyncTest(.DELETE, "/v2/Applications/\(appFound!.uuid)",token:token)
        XCTAssertEqual(deleteApp.status.code , 400)
        let errorResp = try deleteApp.content.decode(ErrorDto.self)
        XCTAssertEqual(errorResp.reason , "ApplicationError.notAnApplicationAdministrator")
    }
    
    func testAppDetail() throws {
        var appDto = appDtoiOS
        appDto.base64IconData = "data:image/png;base64,\(base64EncodedData)"
        try createApplication(appData: appDto)
        
        //login
        let token = try login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
        
        let appFound = try findApp(token: token, name: appDtoiOS.name)
        
        /*
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode(Paginated<ApplicationSummaryDto>.self).wait()
        
        let appFound = apps.data.first*/
        XCTAssertNotNil(appFound)
        
        //check detail
        let detailResp = try app.clientSyncTest(.GET, "/v2/Applications/\(appFound!.uuid)",token:token)
        print(detailResp.content)
        XCTAssertEqual(detailResp.status.code , 200)
        let app = try detailResp.content.decode(ApplicationDto.self)
        XCTAssertTrue(app.iconUrl?.contains("/v2/Applications/\(app.uuid)/icon") ?? false )
        XCTAssertEqual(app.adminUsers.count , 1)
        XCTAssertEqual(app.availableBranches , [])
        XCTAssertNotNil(app.apiKey)
         XCTAssertNil(app.maxVersionSecretKey)
    }
    
    func testAppDetailNotAdmin() throws {
        try testCreateMultiple()
        
        //login
        let token = try login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
        
        let appFound = try findApp(token: token, name: appDtoAndroid.name)
        /*
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode(Paginated<ApplicationSummaryDto>.self).wait()
        
        //find not admin app
        let appFound = apps.data.first(where:{ $0.name == appDtoAndroid.name})
        */
        //check detail
        let detailResp = try app.clientSyncTest(.GET, "/v2/Applications/\(appFound!.uuid)",token:token)
        let app = try detailResp.content.decode(ApplicationDto.self)
        XCTAssertNil(app.apiKey)
    }
    
    func testAddAdminUser() throws {
        try testCreateMultiple()
        //login
        let token = try login(withEmail: userANDROID.email, password: userANDROID.password, inside: app).token
        /*
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode(Paginated<ApplicationSummaryDto>.self).wait()
        
        let appFound = apps.data.first(where:{ $0.name == appDtoAndroid.name})*/
        let appFound = try findApp(token: token, name: appDtoAndroid.name)
        XCTAssertNotNil(appFound)
        
        //add admin
        let adminEscaped = userIOS.email.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        let resp = try app.clientSyncTest(.PUT, "/v2/Applications/\(appFound!.uuid)/adminUsers/\(adminEscaped!)",token:token)
        print(resp.content)
        XCTAssertEqual(resp.status.code , 200)
        
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
        /*
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode([ApplicationSummaryDto].self).wait()
        
        let appFound = apps.first(where:{ $0.name == appDtoAndroid.name})*/
        let appFound = try findApp(token: token, name: appDtoAndroid.name)
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
        /*
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode([ApplicationSummaryDto].self).wait()
        
        let appFound = apps.first(where:{ $0.name == appDtoAndroid.name})*/
        let appFound = try findApp(token: token, name: appDtoAndroid.name)
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
        /*
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode([ApplicationSummaryDto].self).wait()
        
        let appFound = apps.first(where:{ $0.name == appDtoAndroid.name})*/
        let appFound = try findApp(token: token, name: appDtoAndroid.name)
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
        
        let application = try findApp(token: token, name: appDtoAndroid.name)
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
        
        let application = try findApp(token: token, name: appDtoAndroid.name)
        XCTAssertNotNil(application)
        
        //invalid email
        let adminEscaped = userANDROID.email.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        let resp = try app.clientSyncTest(.DELETE, "/v2/Applications/\(application!.uuid)/adminUsers/\(adminEscaped!)",token:token)
        print(resp.content)
        XCTAssertEqual(resp.http.status.code , 400)
        let errorResp = try resp.content.decode(ErrorDto.self).wait()
        XCTAssertEqual(errorResp.reason , "ApplicationError.notAnApplicationAdministrator")
    }
    
    func testAdministeredApps() throws {
        try testCreateMultiple()
        let token = try login(withEmail: userANDROID.email, password: userANDROID.password, inside: app).token
        let me = try profile(with: token, inside: app)
        XCTAssertEqual(me.administeredApplications.count , 1)
        XCTAssertEqual(me.administeredApplications.first?.name , appDtoAndroid.name)
        XCTAssertEqual(me.administeredApplications.first?.platform , appDtoAndroid.platform)
        XCTAssertEqual(me.administeredApplications.first?.description , appDtoAndroid.description)
    }
    /*
    private func findApp(with name:String, token:String) throws -> ApplicationSummaryDto?{
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode([ApplicationSummaryDto].self).wait()
        
        return apps.first(where:{ $0.name == name})
    }*/
    
    private func createAndReturnAppDetail() throws -> (String,ApplicationDto) {
        try testCreate()
        //login
        let token = try login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
        
         let appFound = try findApp(token: token, name: appDtoiOS.name)
        /*
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode([ApplicationSummaryDto].self).wait()
        
        let appFound = apps.first*/
        
        //check detail
        let appDetail = try returnAppDetail(uuid: appFound!.uuid, token: token)
        /*
        let detailResp = try app.clientSyncTest(.GET, "/v2/Applications/\(appFound!.uuid)",token:token)
        print(detailResp.content)
        XCTAssertEqual(detailResp.http.status.code , 200)
        let appDetail = try detailResp.content.decode(ApplicationDto.self).wait()
        */
        return (token,appDetail)
    }
     
    private func returnAppDetail(uuid:String,token:String) throws -> ApplicationDto {
        let detailResp = try app.clientSyncTest(.GET, "/v2/Applications/\(uuid)",token:token)
        XCTAssertEqual(detailResp.http.status.code , 200)
        let appDetail = try detailResp.content.decode(ApplicationDto.self).wait()
        return appDetail
    }
    
    func testApplicationIcon() throws {
       
        let appDto = ApplicationCreateDto(name: "test App iOS", platform: Platform.ios, description: "bla bla", base64IconData: "data:image/png;base64,\(base64EncodedData)", enableMaxVersionCheck:  nil)
        
        
        try createApplication(appData: appDto)
        //login
        let token = try login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
        
        let appFound = try findApp(token: token, name: "test App iOS")
        /*
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let apps = try allAppsResp.content.decode([ApplicationSummaryDto].self).wait()
        
        let appFound = apps.first*/
        XCTAssertNotNil(appFound?.iconUrl)
        
        //check detail
        var iconResp = try app.clientSyncTest(.GET, "/v2/Applications/\(appFound!.uuid)/icon")
        let responseData = iconResp.body.readData(length: iconResp.body.readableBytes)
        print(iconResp.content)
        XCTAssertEqual(responseData,Data(base64Encoded: base64EncodedData))
        XCTAssertEqual(iconResp.content.contentType?.serialize(), "image/png")
        
        //check if result is same as it from app
        print("retrieve with url :\(appFound?.iconUrl)")
        var icon = try app.clientSyncTest(.GET, appFound!.iconUrl!,isAbsoluteUrl:true)
        let iconData = icon.body.readData(length: icon.body.readableBytes)
        
        XCTAssertEqual(iconData,responseData)
    }
    
    func testRetrieveVersion() throws {
        let (token,appDetail) = try createAndReturnAppDetail()
        
        let fileData = try ArtifactsContollerTests.fileData(name: "calculator", ext: "ipa")
        _ = try ArtifactsContollerTests.uploadArtifactSuccess(contentFile: fileData, apiKey: appDetail.apiKey!, branch: "master", version: "1.2.3", name: "prod", contentType:ipaContentType, inside: app)
        
        let allVersions = try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/versions",token:token)
        let versions = try allVersions.content.decode(Paginated<ArtifactDto>.self).wait()
        XCTAssertEqual(versions.data.count,1)
        XCTAssertEqual(versions.data.first?.branch, "master")
        XCTAssertEqual(versions.data.first?.version,"1.2.3")
        XCTAssertEqual(versions.data.first?.name,"prod")
       // app/{appId}/versions?pageIndex=1&limitPerPage=30&branch=master'
    }
    
    func uploadArtifact(branches:[String],names:[String] = ["prod"], numberPerBranches:Int,apiKey:String, mediaType:HTTPMediaType = ipaContentType) throws {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 3
        
        for branch in branches {
            for idx in 0..<numberPerBranches {
                let fileData:Data
                if mediaType == ipaContentType {
                   fileData = try ArtifactsContollerTests.fileData(name: "calculator", ext: "ipa")
                }else {
                    fileData = try ArtifactsContollerTests.fileData(name: "testdroid-sample-app", ext: "apk")
                }
                let version = formatter.string(from: NSNumber(value: idx))
                for name in names {
                     _ = try ArtifactsContollerTests.uploadArtifactSuccess(contentFile: fileData, apiKey: apiKey, branch: branch, version: "1.2.\(version!)", name: name, contentType:mediaType, inside: app)
                   // Thread.sleep(forTimeInterval: 0.3)
                }
               
            }
        }
    }
    
    func uploadLatestArtifact(numberOfUpload:Int,apiKey:String) throws {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 3
        
        for idx in 0..<numberOfUpload {
            let fileData = try ArtifactsContollerTests.fileData(name: "calculator", ext: "ipa")
            let version = formatter.string(from: NSNumber(value: idx))
            _ = try ArtifactsContollerTests.uploadArtifactSuccess(contentFile: fileData, apiKey: apiKey, branch: "latest", version: nil, name: "prod_\(version!)", contentType:ipaContentType, inside: app)
        }
    }
    
    func testRetrieveVersions() throws {
        let (token,appDetail) = try createAndReturnAppDetail()
        try uploadArtifact(branches: ["master","dev"], numberPerBranches: 25, apiKey: appDetail.apiKey!)
        /*
        for idx in 0..<50 {
            let fileData = try ArtifactsContollerTests.fileData(name: "calculator", ext: "ipa")
            _ = try ArtifactsContollerTests.uploadArtifactSuccess(contentFile: fileData, apiKey: appDetail.apiKey!, branch: "master", version: "1.2.\(idx)", name: "prod", contentType:ipaContentType, inside: app)
        }*/
        
        let allVersions = try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/versions",token:token)
        var versions = try allVersions.content.decode(Paginated<ArtifactDto>.self).wait()
        XCTAssertEqual(versions.data.count, 50)
        
        //Check latest is empty
        let latestVersions = try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/versions/latest",token:token)
        versions = try latestVersions.content.decode(Paginated<ArtifactDto>.self).wait()
        XCTAssertEqual(versions.data.count, 0)
        
        // app/{appId}/versions?pageIndex=1&limitPerPage=30&branch=master'
    }
    
    func testRetrieveVersionsGrouped() throws {
        let (token,appDetail) = try createAndReturnAppDetail()
        try uploadArtifact(branches: ["master","dev"], names: ["prod","dev","demo"], numberPerBranches: 25, apiKey: appDetail.apiKey!)
        
        let allVersions = try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/versions/grouped",token:token)
        var groupedVersions = try allVersions.content.decode(Paginated<ArtifactGroupedDto>.self).wait()
        XCTAssertEqual(groupedVersions.data.count, 50)
        
        //Check latest is empty
        let latestVersions = try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/versions/latest",token:token)
        let versions = try latestVersions.content.decode(Paginated<ArtifactDto>.self).wait()
        XCTAssertEqual(versions.data.count, 0)
        
        // app/{appId}/versions?pageIndex=1&limitPerPage=30&branch=master'
    }
    
    func testRetrieveVersionsByPages() throws {
     /*   let (token,appDetail) = try createAndReturnAppDetail()
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
        XCTAssertEqual(versions.count, 0)*/
    }
    
    func testRetrieveVersionsByBranch() throws {
        let (token,appDetail) = try createAndReturnAppDetail()
        let branches = ["master","dev","release"]
        try uploadArtifact(branches: branches , numberPerBranches: 10, apiKey: appDetail.apiKey!)
        
        let allVersions = try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/versions",token:token)
        let versions = try allVersions.content.decode(Paginated<ArtifactDto>.self).wait()
        XCTAssertEqual(versions.data.count, 30)
        
        for branch in branches {
            let allVersions = try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/versions?branch=\(branch)",token:token)
            let versions = try allVersions.content.decode(Paginated<ArtifactDto>.self).wait()
            XCTAssertEqual(versions.data.count, 10)
            for version in versions.data {
                XCTAssertEqual(version.branch, branch)
            }
            XCTAssertEqual(versions.data.first?.version, "1.2.009")
        }
    }
    
    func testRetrieveVersionsByBranchAndLatest() throws {
        let (token,appDetail) = try createAndReturnAppDetail()
        try uploadLatestArtifact(numberOfUpload: 10, apiKey: appDetail.apiKey!)
        
        try uploadArtifact(branches: ["master"] , numberPerBranches: 10, apiKey: appDetail.apiKey!)
        let allVersions = try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/versions",token:token)
        let versions = try allVersions.content.decode(Paginated<ArtifactDto>.self).wait()
        XCTAssertEqual(versions.data.count, 10)
    }
    
    func testRetrieveVersionsLatest() throws {
        let (token,appDetail) = try createAndReturnAppDetail()
        try uploadLatestArtifact(numberOfUpload: 10, apiKey: appDetail.apiKey!)
        
        let allLatestVersions = try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/versions/latest",token:token)
       // print(allLatestVersions)
        let latestVersions = try allLatestVersions.content.decode(Paginated<ArtifactDto>.self).wait()
        XCTAssertEqual(latestVersions.data.count, 10)
        
        //check "normal" versions are empty
        let allVersions = try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/versions",token:token)
        print(allVersions)
        let versions = try allVersions.content.decode(Paginated<ArtifactDto>.self).wait()
        XCTAssertEqual(versions.data.count, 0)
        XCTAssertEqual(versions.page.position.max, 0)
    }
    
    func testAppDetailWithBranches() throws {
        let (token,appDetail) = try createAndReturnAppDetail()
        XCTAssertEqual(appDetail.availableBranches, [])
        
        try uploadArtifact(branches: ["master","dev"] , numberPerBranches: 2, apiKey: appDetail.apiKey!)
        
        var app = try returnAppDetail(uuid: appDetail.uuid, token: token)
        XCTAssertEqual(app.availableBranches, ["master","dev"])
        
        try uploadLatestArtifact(numberOfUpload: 2, apiKey: appDetail.apiKey!)
        app = try returnAppDetail(uuid: appDetail.uuid, token: token)
        XCTAssertEqual(app.availableBranches, ["master","dev"])
    }
    
    func testFavoritesApplications() throws {
        _ = try register(registerInfo: userIOS, inside: app)
        //login
        let token = try login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
        
        try ApplicationsControllerTests.populateApplications(nbre: 20, inside: app, token: token)
        let allAppsResp = try app.clientSyncTest(.GET, "/v2/Applications",token:token)
        let allApps = try allAppsResp.content.decode(Paginated<ApplicationSummaryDto>.self).wait()
        
        let uuids = allApps.data.prefix(10).map{$0.uuid}
        
        let updateInfo = UpdateUserDto(favoritesApplicationsUUID:uuids)
        let updateResp = try app.clientSyncTest(.PUT, "/v2/Users/me", updateInfo ,  token: token)
        XCTAssertEqual(updateResp.http.status.code , 200)
        
        //retrieve favorites Apps
        let favoritesAppResp = try app.clientSyncTest(.GET, "/v2/Applications/favorites", token: token)
        print(favoritesAppResp.content)
        let favoritesApp = try favoritesAppResp.content.decode([ApplicationSummaryDto].self).wait()
        let favoritesAppUuid = favoritesApp.map{$0.uuid}
       // XCTAssertNotEqual(favoritesAppUuid,uuids)
        XCTAssertEqual(Set(favoritesAppUuid),Set(uuids))
    }
    
    func testMaxVersion() throws {
        var appWithMaxVersion = appDtoiOS
        appWithMaxVersion.enableMaxVersionCheck = true
        try createApplication(appData: appWithMaxVersion)
        let loginDto = try login(withEmail: userIOS.email, password: userIOS.password, inside: app)
        let token = loginDto.token
        
        let appFound = try findApp(token: token, name: appWithMaxVersion.name)
        let appDetail = try returnAppDetail(uuid: appFound!.uuid, token: token)
        XCTAssertNotNil(appDetail.maxVersionSecretKey)
        let appSecret = appDetail.maxVersionSecretKey!
        
        //upload artifacts
        let fileData = try ArtifactsContollerTests.fileData(name: "calculator", ext: "ipa")
        var version = "1.0.0"
        let branch = "test"
        _ = try ArtifactsContollerTests.uploadArtifactSuccess(contentFile: fileData, apiKey: appDetail.apiKey!, branch: branch, version: version, name: "prod", contentType:ipaContentType, inside: app)
        
        //retrieve latest
        //v2/Applications/{appUUID}/maxversion/{branch}/{name}
        var query = generateMaxVersionUrl(secret: appSecret, branch: "test")
        var maxVersionResp =  try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/maxversion/test/prod",query,token:token)
        var maxVersion = try maxVersionResp.content.decode(MaxVersionArtifactDto.self).wait()
        XCTAssertEqual(maxVersion.branch, branch)
        XCTAssertEqual(maxVersion.version, version)
        
         version = "1.0.1"
        _ = try ArtifactsContollerTests.uploadArtifactSuccess(contentFile: fileData, apiKey: appDetail.apiKey!, branch: branch, version: version, name: "prod", contentType:ipaContentType, inside: app)
        query = generateMaxVersionUrl(secret: appSecret, branch: "test")
        maxVersionResp =  try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/maxversion/test/prod",query,token:token)
        maxVersion = try maxVersionResp.content.decode(MaxVersionArtifactDto.self).wait()
        XCTAssertEqual(maxVersion.branch, branch)
        XCTAssertEqual(maxVersion.version, version)
        
        //test direct download
        let ipaFile = try app.clientSyncTest(.GET, maxVersion.info.directLinkUrl,isAbsoluteUrl:true)
        #if os(Linux)
            //URLSEssion on linux doens not handle redirect by default
            XCTAssertEqual(ipaFile.http.status, .seeOther)
            XCTAssertEqual( ipaFile.http.headers.firstValue(name: .location),TestingStorageService.defaultIpaUrl)
        #else
            XCTAssertTrue(ipaFile.content.contentType == .binary)
            XCTAssertEqual(ipaFile.body.readableBytes,fileData.count)
        #endif
    }
    
    func testMaxVersionNotActivated() throws {
        let (token,appDetail) = try createAndReturnAppDetail()
        
        let query = generateMaxVersionUrl(secret: "secret", branch: "test")
        let maxVersionResp =  try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/maxversion/test/prod",query,token:token)
        XCTAssertEqual(maxVersionResp.http.status.code, 400)
        let errorResp = try maxVersionResp.content.decode(ErrorDto.self).wait()
        XCTAssertEqual(errorResp.reason , "ApplicationError.disabledFeature")
    }
    
    func testMaxVersionKO() throws {
        var appWithMaxVersion = appDtoiOS
        appWithMaxVersion.enableMaxVersionCheck = true
        try createApplication(appData: appWithMaxVersion)
        let loginDto = try login(withEmail: userIOS.email, password: userIOS.password, inside: app)
        let token = loginDto.token
        
        let appFound = try findApp(token: token, name: appWithMaxVersion.name)
        let appDetail = try returnAppDetail(uuid: appFound!.uuid, token: token)
        XCTAssertNotNil(appDetail.maxVersionSecretKey)
        let appSecret = appDetail.maxVersionSecretKey!
        
        //after 30 seconds delay
        var query = generateMaxVersionUrl(secret: appSecret, branch: "test",dateDelta: 31) //max delay of 30secs
        var maxVersionResp =  try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/maxversion/test/prod",query,token:token)
        XCTAssertEqual(maxVersionResp.http.status.code, 400)
        var errorResp = try maxVersionResp.content.decode(ErrorDto.self).wait()
        XCTAssertEqual(errorResp.reason , "ApplicationError.expirationTimestamp")
        
        //not artifact found
        query = generateMaxVersionUrl(secret: appSecret, branch: "test")
        maxVersionResp =  try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/maxversion/test/prod",query,token:token)
        XCTAssertEqual(maxVersionResp.http.status.code, 400)
        errorResp = try maxVersionResp.content.decode(ErrorDto.self).wait()
        XCTAssertEqual(errorResp.reason , "ArtifactError.notFound")
        
        //invalid hash
        query = generateMaxVersionUrl(secret: "toto", branch: "test")
        maxVersionResp =  try app.clientSyncTest(.GET, "/v2/Applications/\(appDetail.uuid)/maxversion/test/prod",query,token:token)
        XCTAssertEqual(maxVersionResp.http.status.code, 400)
        errorResp = try maxVersionResp.content.decode(ErrorDto.self).wait()
        XCTAssertEqual(errorResp.reason , "ApplicationError.invalidSignature")
    }
    
    private func generateMaxVersionUrl(secret:String,branch:String,dateDelta:TimeInterval = 0) -> [String:String] {
        let ts = Date().timeIntervalSince1970 + dateDelta
        let stringToHash = "ts=\(ts)&branch=\(branch)&hash=\(secret)"
        let generatedHash = stringToHash.md5()
        
        return ["ts": "\(ts)", "branch":branch, "hash" : generatedHash]
    }
}

extension ApplicationsControllerTests {
    class func createApp(with info:ApplicationCreateDto, inside app:Application,token:String?) throws -> ApplicationDto {
        //let body = try info.convertToHTTPBody()
        let result = try app.clientSyncTest(.POST, "/v2/Applications", info,token:token)
        print(result.content)
        return try result.content.decode(ApplicationDto.self).wait()
    }
    class func populateApplications(nbre:Int,tempo:Double = 0,inside app:Application,token:String) throws{
        for i in 1...nbre {
            if tempo > 0.0 {
                Thread.sleep(forTimeInterval: tempo)
            }
            let platform = i%2 == 0 ? Platform.android : Platform.ios
            let appDto = ApplicationCreateDto(name: "Application\(String(format: "%03d",i))", platform: platform, description: "Desc App", base64IconData: nil, enableMaxVersionCheck: nil)
            _ = try createApp(with: appDto, inside: app, token: token)
        }
    }
}
