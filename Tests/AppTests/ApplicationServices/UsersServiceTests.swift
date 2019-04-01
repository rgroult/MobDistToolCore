//
//  UserServiceTests.swift
//  AppTests
//
//  Created by Rémi Groult on 26/02/2019.
//

//import App
import XCTest
import Vapor
import Meow
@testable import App

final class UsersServiceTests: BaseAppTests {
    
    override func setUp() {
        super.setUp()
        
    }
    
    func dropNormalUsers(){
        XCTAssertNoThrow(try context.deleteAll(User.self, where: Query.valEquals(field: "isSystemAdmin", val: false)).wait())
    }
    
    func testCreateNormalUser() throws {
        let user = try createUser(name: "toto", email: "toto@toto.com", password: "pwd", into: context).wait()
        XCTAssertNotNil(user)
        XCTAssertEqual(user.name, "toto")
        XCTAssertEqual(user.email, "toto@toto.com")
        XCTAssertEqual(user.isActivated, false)
        XCTAssertEqual(user.isSystemAdmin, false)
        XCTAssertNotNil(user.activationToken)
        
        //delete user
        XCTAssertNoThrow(try deleteUser(withEmail: "toto@toto.com", into: context).wait())
    }
    
    func testCreateActivatedUser() throws {
        let user = try createUser(name: "toto", email: "toto@toto.com", password: "pwd",isActivated:true, into: context).wait()
        XCTAssertNotNil(user)
        XCTAssertEqual(user.name, "toto")
        XCTAssertEqual(user.email, "toto@toto.com")
        XCTAssertEqual(user.isActivated, true)
        XCTAssertEqual(user.isSystemAdmin, false)
        XCTAssertNil(user.activationToken)
        
        //delete user
        XCTAssertNoThrow(try deleteUser(withEmail: "toto@toto.com", into: context).wait())
    }
    
    func testCreateIdenticalUser() throws {
        XCTAssertNoThrow(try createUser(name: "toto", email: "toto@toto.com", password: "pwd", into: context).wait())
        XCTAssertThrowsError(try createUser(name: "toto", email: "toto@toto.com", password: "pwd", into: context).wait(), "Should throw user error") { error in
            XCTAssertTrue((error as? UserError) == UserError.alreadyExist)
        }
        //delete user
        XCTAssertNoThrow(try deleteUser(withEmail: "toto@toto.com", into: context).wait())
    }
    
    func testDeleteTwice(){
        XCTAssertNoThrow(try createUser(name: "toto", email: "toto@toto.com", password: "pwd", into: context).wait())
        //delete user
        XCTAssertNoThrow(try deleteUser(withEmail: "toto@toto.com", into: context).wait())
        //delete user again
        XCTAssertThrowsError(try deleteUser(withEmail: "toto@toto.com", into: context).wait(), "") { error in
            XCTAssertTrue((error as? UserError) == UserError.notFound)
        }
    }
    
    func testAdminUser()throws{
        let user = try createUser(name: "toto", email: "toto@toto.com", password: "pwd",isSystemAdmin:true, isActivated: true, into: context).wait()
        XCTAssertNotNil(user)
        XCTAssertEqual(user.name, "toto")
        XCTAssertEqual(user.email, "toto@toto.com")
        XCTAssertEqual(user.isActivated, true)
        XCTAssertEqual(user.isSystemAdmin, true)
        
        //delete user
        XCTAssertNoThrow(try deleteUser(withEmail: "toto@toto.com", into: context).wait())
    }
    
    func testResetUser () throws {
        var user = try createUser(name: "toto", email: "toto@toto.com", password: "pwd", isActivated:true, into: context).wait()
        XCTAssertNil(user.activationToken)
        XCTAssertEqual(user.isActivated, true)
        user = try resetUser(user: user, newPassword: "toto", into: context).wait()
        XCTAssertNotNil(user.activationToken)
        XCTAssertEqual(user.isActivated, false)
        
        //delete user
        XCTAssertNoThrow(try deleteUser(withEmail: "toto@toto.com", into: context).wait())
    }
    
    func testLoginUser() throws {
        var user = try createUser(name: "toto", email: "toto@toto.com", password: "pwd", into: context).wait()
        XCTAssertNil(user.lastLogin)
        user = try findUser(by: user.email, and: "pwd", updateLastLogin:false,into: context).wait()
        //do not update login date
        XCTAssertNil(user.lastLogin)
        user = try findUser(by: user.email, and: "pwd", updateLastLogin:true,into: context).wait()
        XCTAssertNotNil(user.lastLogin)
        
        //delete user
        XCTAssertNoThrow(try deleteUser(withEmail: user.email, into: context).wait())
    }
    
    func testLoginUserFailed() throws {
        let user = try createUser(name: "toto", email: "toto@toto.com", password: "pwd", into: context).wait()
        XCTAssertThrowsError(try findUser(by: user.name, and: "totot", into: context).wait(), "") { error in
            XCTAssertTrue((error as? UserError) == UserError.invalidLoginOrPassword)
        }
        XCTAssertThrowsError(try findUser(by: "rere", and: "pwd", into: context).wait(), "") { error in
            XCTAssertTrue((error as? UserError) == UserError.invalidLoginOrPassword)
        }
    }
}

