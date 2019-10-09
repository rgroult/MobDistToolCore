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
        XCTAssertTrue(me.isActivated ?? false)
        
      /*  try app.clientTest(.GET, "/v2/Users/me",token:token){ res in
            print(res.content)
            let me = try res.content.decode(UserDto.self).wait()
            XCTAssertTrue(me.email == userIOS.email)
            XCTAssertTrue(me.isActivated ?? false)
        }*/
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
