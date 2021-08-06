//
//  ApplicationServiceTests.swift
//  AppTests
//
//  Created by Rémi Groult on 27/02/2019.
//
import XCTest
import Vapor
import Meow
@testable import App

let normalUSerInfo = RegisterDto(email: "toto@toto.Com", name: "toto", password: "pwd")

 final class ApplicationServiceTests: BaseAppTests {
    var normalUser:User!
    var adminUser:User!
    
    override func setUp() {
        super.setUp()
        context = try app.meow
        XCTAssertNoThrow(normalUser =  try createUser(name: normalUSerInfo.name, email: normalUSerInfo.email, password: normalUSerInfo.password,isActivated:true, into: context).wait())
        let adminUser = try? findUser(by: "admin@localhost.com", into: context).wait()
        XCTAssertNotNil(adminUser)
        self.adminUser = adminUser!
    }
    
    override func tearDown() {
        XCTAssertNoThrow(try deleteUser(withEmail: normalUser.email, into: context).wait())
       
        //delete all apps
        XCTAssertNoThrow(try context.collection(for: MDTApplication.self).deleteAll(where: []).wait())
        //XCTAssertNoThrow(try context.deleteAll(MDTApplication.self,where:Query()).wait())
         super.tearDown()
    }
    
    func testCreateApplication() throws {
        let app = try createApplication(name: "testApp", platform: Platform.android, description: "testApp", adminUser: normalUser, into: context).wait()
        XCTAssertEqual(app.name, "testApp")
        XCTAssertEqual(app.platform, .android)
        XCTAssertEqual(app.description,"testApp")
        XCTAssertEqual(app.adminUsers.count, 1)
        XCTAssertEqual(app.adminUsers.first, Reference(to: normalUser))
    }
    
    func testExistingApp() throws {
        try testCreateApplication()
        
        XCTAssertThrowsError(try testCreateApplication(), "") { error in
            XCTAssertEqual((error as? ApplicationError), ApplicationError.alreadyExist)
        }
    }
    
    func testDeleteApplication() throws {
        //delete not found
        XCTAssertThrowsError(try deleteApplication(with: "testApp", and:Platform.android, into: context).wait(), "") { error in
            XCTAssertTrue((error as? ApplicationError) == ApplicationError.notFound)
        }
        
        try testCreateApplication()
        
        //delete app
        XCTAssertNoThrow(try deleteApplication(with: "testApp", and:Platform.android, into: context).wait())
        
        //delete again
        XCTAssertThrowsError(try deleteApplication(with: "testApp", and:Platform.android, into: context).wait(), "") { error in
            XCTAssertTrue((error as? ApplicationError) == ApplicationError.notFound)
        }
    }
    
    func testUpdateApplicationAdminUsers() throws {
        try testCreateApplication()
        //find app
        
        var app:MDTApplication? = try findApplications(for: normalUser, into: context).firstResult().wait()
        XCTAssertNotNil(app)
        XCTAssertEqual(app!.adminUsers.count, 1)
        _ = try app!.removeAdmin(user: normalUser, into: context).wait()
        
        XCTAssertEqual(app!.adminUsers.count, 0)
        
        //find app
        XCTAssertNil(try findApplications(for: normalUser, into: context).firstResult().wait())
        
        //reload app
        app = try findApplicationsPaginated(pagination: .init(additionalStages: [], currentPageIndex: 0, pageSize: 999), into: context, additionalQuery: nil).wait()?.data.first
       // app = try findApplications(into: context,additionalQuery:nil).1.firstResult().wait()
        XCTAssertEqual(app?.adminUsers.count, 0)
        
        //add user as admin
        _ = try app?.addAdmin(user: normalUser, into: context).wait()
        XCTAssertNotNil(app)
        //reload app
        let reloadApp:MDTApplication? = try findApplications(for: normalUser, into: context).firstResult().wait()
        XCTAssertNotNil(reloadApp)
        XCTAssertEqual(app?._id, reloadApp?._id)
    }
    
    func testFindApplication() throws {
        try testCreateApplication()
        
        //find app
        let app:MDTApplication? = try findApplications(for: normalUser, into: context).firstResult().wait()
        XCTAssertNotNil(app)
        
        //find by uuid
        XCTAssertEqual(app!._id, try findApplication(uuid: app!.uuid, into: context).wait()?._id)
        
        //find by apiKey
        XCTAssertEqual(app!._id, try findApplication(apiKey: app!.apiKey, into: context).wait()?._id)
    }
}

