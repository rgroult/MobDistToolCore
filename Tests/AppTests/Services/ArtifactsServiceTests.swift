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
        
        try addArtifact(branches: ["master","test"], numberPerBranches: 10, app: app)
        let (cursor,total) = try findAndSortArtifacts(app: app, selectedBranch: nil, excludedBranch: App.lastVersionName, into: context)
       
        let allResults = try cursor.getAllResults().wait()
        let totalResults = try total.wait()
        XCTAssertEqual(totalResults, 20)
        allResults.forEach { art in
            XCTAssertEqual(art.artifacts.count, 2)
        }
    }
    
    func addArtifact(branches:[String], numberPerBranches:Int,app:MDTApplication) throws {
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

    func testDeleteArtifactForApplication() throws {
        //count all artifacts
        XCTAssertEqual(try context.count(MDTApplication.self).wait(), 0)
        XCTAssertEqual(try context.count(Artifact.self).wait(), 0)


        let app = try createApplication(name: "testApp", platform: Platform.android, description: "testApp", adminUser: normalUser, into: context).wait()
        let app2 = try createApplication(name: "testApp2", platform: Platform.ios, description: "testApp", adminUser: normalUser, into: context).wait()

        try addArtifact(branches: ["master","test"], numberPerBranches: 10, app: app)
        try addArtifact(branches: ["master","test"], numberPerBranches: 10, app: app2)

        //count all artifacts
        XCTAssertEqual(try context.count(MDTApplication.self).wait(), 2)
        XCTAssertEqual(try context.count(Artifact.self).wait(), 80)

        //delete one App
        try deleteAllArtifacts(app: app2, storage: TestingStorageService(), into: context).wait()
        try deleteApplication(by: app2, into: context).wait()


        //count all artifacts
        XCTAssertEqual(try context.count(MDTApplication.self).wait(), 1)
        XCTAssertEqual(try context.count(Artifact.self).wait(), 40)
    }
}
