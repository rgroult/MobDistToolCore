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

let userIOS = RegisterDto(email: "toto@toto.com", name: "toto", password: "passwd")
let userANDROID = RegisterDto(email: "titi@titi.com", name: "titi", password: "passwd")

final class UsersControllerAutomaticRegistrationTests: BaseAppTests {
    func testRegister() throws{
        let registerReq = userIOS
        let registerJSON = try JSONEncoder().encode(registerReq)
        
        let body = registerJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/register", body){ res in
            XCTAssertNotNil(res)
            // let token = res.content.get(String.self, at: "token")
            print(res.content)
            let registerResp = try res.content.decode(UserDto.self).wait()
            XCTAssertEqual(registerResp.email, registerReq.email)
            XCTAssertEqual(registerResp.name, registerReq.name)
            XCTAssertEqual(registerResp.isActivated, true)
            XCTAssertEqual(registerResp.isSystemAdmin, false)
            print(registerResp)
        }
    }
    
    func testLogin() throws {
        try testRegister()
        XCTAssertNoThrow(try login(withEmail: userIOS.email, password: userIOS.password, inside: app))
    }
    
    func testForgotPassword() throws {
        try testRegister()
        let forgot = ForgotPasswordDto(email: userIOS.email)
        let bodyJSON = try JSONEncoder().encode(forgot)
        let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/forgotPassword", body){ res in
            print(res.content)
            XCTAssertEqual(res.http.status.code , 400)
            XCTAssertNotNil(res)
            let resp = try res.content.decode(ErrorDto.self).wait()
            XCTAssertTrue(resp.reason == "Contact an administrator to retrieve new password")
        }
    }
    
}

final class UsersControllerNoAutomaticRegistrationTests: BaseAppTests {
    override func setUp() {
        var env = Environment.xcode
        env.arguments += ["-DautomaticRegistration=false"]
        configure(with: env)
    }
    
    func testRegister() throws{
        let registerReq = userIOS
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
    
    func testActivation() throws {
        try testRegister()
        //retrieve activation token
        let userFound = try findUser(by: userIOS.email, into: context).wait()
        XCTAssertNotNil(userFound)
        guard let user = userFound else { return }
       
        XCTAssertEqual(user.isActivated, false)
        //activation
        try app.clientTest(.GET, "/v2/Users/activation?activationToken=\(user.activationToken!)", nil){ res in
            XCTAssertNotNil(res)
            XCTAssertEqual(res.http.status.code , 200)
        }
    }
    
    func testActivationKO() throws {
        try testRegister()
        //retrieve activation token
        let userFound = try findUser(by: userIOS.email, into: context).wait()
        XCTAssertNotNil(userFound)
        guard let user = userFound else { return }
        
        XCTAssertEqual(user.isActivated, false)
        //activation
        try app.clientTest(.GET, "/v2/Users/activation?activationToken=BadToken)", nil){ res in
            print(res.content)
            XCTAssertNotNil(res)
            XCTAssertEqual(res.http.status.code , 400)
            let errorResp = try res.content.decode(ErrorDto.self).wait()
            XCTAssertTrue(errorResp.reason == "Invalid activationToken")
        }
    }
    
    func testLoginNotActivated() throws {
        try testRegister()
        //login
        let login = LoginReqDto(email: userIOS.email, password: userIOS.password)
        let bodyJSON = try JSONEncoder().encode(login)
        
        let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/login", body){ res in
            print(res.content)
            XCTAssertEqual(res.http.status.code , 400)
            let errorResp = try res.content.decode(ErrorDto.self).wait()
            XCTAssertTrue(errorResp.reason == "UserError.notActivated")
        }
    }
    
    
    func testLogin() throws {
        try testActivation()
        //login
        let login = LoginReqDto(email: userIOS.email, password: userIOS.password)
        let bodyJSON = try JSONEncoder().encode(login)
        
        let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/login", body){ res in
            print(res.content)
            XCTAssertEqual(res.http.status.code , 200)
            XCTAssertNotNil(res)
            let loginResp = try res.content.decode(LoginRespDto.self).wait()
            XCTAssertTrue(loginResp.email == userIOS.email)
            XCTAssertTrue(loginResp.name == userIOS.name)
            XCTAssertNotNil(loginResp.token)
        }
    }
    
    func testLoginKo() throws {
        try testActivation()
        //login
        let login = LoginReqDto(email: userIOS.email, password: "bad password")
        let bodyJSON = try JSONEncoder().encode(login)
        
        let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/login", body){ res in
            print(res.content)
            XCTAssertEqual(res.http.status.code , 400)
            XCTAssertNotNil(res)
            let errorResp = try res.content.decode(ErrorDto.self).wait()
            XCTAssertTrue(errorResp.reason == "UserError.invalidLoginOrPassword")
        }
    }
    
    func testForgotPassword() throws {
        try testActivation()
        let forgot = ForgotPasswordDto(email: userIOS.email)
        let bodyJSON = try JSONEncoder().encode(forgot)
        let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/forgotPassword", body){ res in
            print(res.content)
            XCTAssertEqual(res.http.status.code , 200)
            XCTAssertNotNil(res)
            let resp = try res.content.decode(MessageDto.self).wait()
            XCTAssertTrue(resp.message == "Your account has been temporarily desactivated, a email with new password and activation link was sent")
        }
    }
    
    func testForgotPasswordCheckAccountIsDisabled() throws {
        try testForgotPassword()
        let password = "password"
        //force reset to have real password
        guard let user = try findUser(by: userIOS.email, into: context).wait() else { throw "Not Found" }
        try resetUser(user: user, newPassword: password, into: context).wait()
        
        //login
        let login = LoginReqDto(email: userIOS.email, password: password)
        let bodyJSON = try JSONEncoder().encode(login)
        
        let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/login", body){ res in
            print(res.content)
            XCTAssertEqual(res.http.status.code , 400)
            let errorResp = try res.content.decode(ErrorDto.self).wait()
            XCTAssertTrue(errorResp.reason == "UserError.notActivated")
        }
    }
    
    func testForgotPasswordKO() throws {
        try testActivation()
        let forgot = ForgotPasswordDto(email: "john@Doe.com")
        let bodyJSON = try JSONEncoder().encode(forgot)
        let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/forgotPassword", body){ res in
            print(res.content)
            XCTAssertEqual(res.http.status.code , 400)
            XCTAssertNotNil(res)
            let errorResp = try res.content.decode(ErrorDto.self).wait()
            XCTAssertTrue(errorResp.reason == "UserError.notFound")
        }
    }
    
    func testMe() throws {
        try testActivation()
        let loginResp = try login(withEmail: userIOS.email,password:userIOS.password,inside:app)
        XCTAssertNotNil(loginResp.token)
        let token = loginResp.token
        
        let me = try profile(with: token, inside: app)
        XCTAssertTrue(me.email == userIOS.email)
        XCTAssertTrue(me.administeredApplications.isEmpty)
        XCTAssertTrue(me.isActivated ?? false)
        XCTAssertFalse(me.isSystemAdmin ?? true)
        XCTAssertNotNil(me.createdAt)
        XCTAssertNotNil(me.lastLogin)
        XCTAssertEqual(me.favoritesApplicationsUUID,[])
        
      /*  try app.clientTest(.GET, "/v2/Users/me",token:token){ res in
            print(res.content)
            let me = try res.content.decode(UserDto.self).wait()
            XCTAssertTrue(me.email == userIOS.email)
            XCTAssertTrue(me.isActivated ?? false)
        }*/
    }
    
    func testUpdate() throws {
        try testActivation()
        var loginResp = try login(withEmail: userIOS.email,password:userIOS.password,inside:app)
        var token = loginResp.token
        
        var me = try profile(with: token, inside: app)
        XCTAssertEqual(me.name, userIOS.name)
        XCTAssertEqual(me.favoritesApplicationsUUID,[])
        //XCTAssertNil(me.)
        let updateInfo = UpdateUserDto(name: "Foo Super User", password: "azerty",favoritesApplicationsUUID:["XXX_XXX-XXX"])
        let updateResp = try app.clientSyncTest(.PUT, "/v2/Users/me", updateInfo.convertToHTTPBody() , token: token)
        //check update resp
        let updatedMe = try updateResp.content.decode(UserDto.self).wait()
        XCTAssertEqual(updatedMe.name, updateInfo.name)
        XCTAssertEqual(updatedMe.favoritesApplicationsUUID, updateInfo.favoritesApplicationsUUID)
        
        //login with old password must failed
        XCTAssertThrowsError(try login(withEmail: userIOS.email,password:userIOS.password,inside:app))
        
        //login with new password
        loginResp = try login(withEmail: userIOS.email,password:updateInfo.password!,inside:app)
        token = loginResp.token
        
        //retrieve profile
        me = try profile(with: token, inside: app)
        //check "updated me"
        XCTAssertEqual(me.name, updateInfo.name)
        XCTAssertEqual(me.favoritesApplicationsUUID, updateInfo.favoritesApplicationsUUID)
        
        //delete app favorites
        let update2Info = UpdateUserDto(name: nil, password: nil,favoritesApplicationsUUID:[])
        let update2Resp = try app.clientSyncTest(.PUT, "/v2/Users/me", update2Info.convertToHTTPBody() , token: token)
        let updated2Me = try update2Resp.content.decode(UserDto.self).wait()
        XCTAssertEqual(updated2Me.favoritesApplicationsUUID, [])
    }
    
    func testUpdateOther() throws {
        try testActivation()
        let loginResp = try login(withEmail: userIOS.email,password:userIOS.password,inside:app)
        let token = loginResp.token
        
        //test update without be a admin
        let updateInfo = UpdateUserDto(name: "Foo Super User", password: "azerty",favoritesApplicationsUUID:["XXX_XXX-XXX"])
        var updateResp = try app.clientSyncTest(.PUT, "/v2/Users/\(userIOS.email)", updateInfo.convertToHTTPBody() , token: token)
        XCTAssertEqual(updateResp.http.status.code, 401)
        //check update resp
        
        let configuration = try MdtConfiguration.loadConfig(from: nil, from: &app.environment)
        let adminToken = try login(withEmail: configuration.initialAdminEmail, password: configuration.initialAdminPassword, inside: app).token
        //retry as admin
        updateResp = try app.clientSyncTest(.PUT, "/v2/Users/\(userIOS.email)", updateInfo.convertToHTTPBody() , token: adminToken)
        XCTAssertEqual(updateResp.http.status.code, 200)
        let updatedDto = try updateResp.content.decode(UserDto.self).wait()
        XCTAssertEqual(updatedDto.name,updateInfo.name)
    }
    
    func testUpdateDelete() throws {
        try testActivation()
        let loginResp = try login(withEmail: userIOS.email,password:userIOS.password,inside:app)
        let token = loginResp.token
        //test update without be a admin
        var deleteResp = try app.clientSyncTest(.DELETE, "/v2/Users/\(userIOS.email)" , token: token)
        XCTAssertEqual(deleteResp.http.status.code, 401)
        
        let configuration = try MdtConfiguration.loadConfig(from: nil, from: &app.environment)
        let adminToken = try login(withEmail: configuration.initialAdminEmail, password: configuration.initialAdminPassword, inside: app).token
        deleteResp = try app.clientSyncTest(.DELETE, "/v2/Users/\(userIOS.email)" , token: adminToken)
        XCTAssertEqual(deleteResp.http.status.code, 200)
    }
}

func profile(with token:String,inside app:Application) throws -> UserDto {
    let result = try app.clientSyncTest(.GET, "/v2/Users/me", token: token)
    return try result.content.decode(UserDto.self).wait()
}

func login(withEmail:String, password:String,inside app:Application) throws -> LoginRespDto {
    //login
    let login = LoginReqDto(email:withEmail, password: password)
    let bodyJSON = try JSONEncoder().encode(login)
    let body = bodyJSON.convertToHTTPBody()
    let result = try app.clientSyncTest(.POST, "/v2/Users/login", body)
    return try result.content.decode(LoginRespDto.self).wait()
}

func register(registerInfo:RegisterDto, inside app:Application) throws -> UserDto {
    //register
    let bodyJSON = try JSONEncoder().encode(registerInfo)
    let body = bodyJSON.convertToHTTPBody()
    let result = try app.clientSyncTest(.POST, "/v2/Users/register", body)
    return try result.content.decode(UserDto.self).wait()
}
