//
//  ArtifactsServiceTests.swift
//  AppTests
//
//  Created by Remi Groult on 11/11/2019.
//

import XCTest
import Vapor
import Meow
@testable import App

final class ArtifactsServiceTests: BaseAppTests {
    var normalUser:User!
    var adminUser:User!
    
    override func setUp() {
        super.setUp()
        XCTAssertNoThrow(context = try app.make(Future<Meow.Context>.self).wait())
        XCTAssertNoThrow(normalUser =  try createUser(name: normalUSerInfo.name, email: normalUSerInfo.email, password: normalUSerInfo.password,isActivated:true, into: context).wait())
        let adminUser = try? findUser(by: "admin@localhost.com", into: context).wait()
        XCTAssertNotNil(adminUser)
        self.adminUser = adminUser!
    }
    
    override func tearDown() {
        XCTAssertNoThrow(try deleteUser(withEmail: normalUser.email, into: context).wait())
       
        //delete all apps
        XCTAssertNoThrow(try context.deleteAll(MDTApplication.self,where:Query()).wait())
         super.tearDown()
    }
    
    func testAddArtifactsAndsort() throws {
        let app = try createApplication(name: "testApp", platform: Platform.android, description: "testApp", adminUser: normalUser, into: context).wait()
        
        try uploadArtifact(branches: ["master","test"], numberPerBranches: 10, app: app)
        
        let cursor = try findAndSortArtifacts(app: app, into: context)
        .forEach(handler: {document in
            print(document)
        })
        
      /*  let artifact = try createArtifact(app: app, name: "test", version: "1.2.3", branch: "test", sortIdentifier: nil, tags: nil)
        artifact.save(to: context).wait()*/
    }
    
    func uploadArtifact(branches:[String], numberPerBranches:Int,app:MDTApplication) throws {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 3
        
        for branch in branches {
            for idx in 0..<numberPerBranches {
                let version = formatter.string(from: NSNumber(value: idx))
                var artifact = try createArtifact(app: app, name: "dev", version: "1.2.\(version!)", branch: branch, sortIdentifier: nil, tags: nil)
                try artifact.save(to: context).wait()
                artifact = try createArtifact(app: app, name: "prod", version: "1.2.\(version!)", branch: branch, sortIdentifier: nil, tags: nil)
                try artifact.save(to: context).wait()
            }
        }
    }
}
