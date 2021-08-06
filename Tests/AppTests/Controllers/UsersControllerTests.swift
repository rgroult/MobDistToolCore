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
        //let registerJSON = try JSONEncoder().encode(registerReq)
        
       // let body = registerJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/register", registerReq){ res in
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
    
    func testRegisterInavlidEmailFormat() throws{
        let registerReq = RegisterDto(email: "toto_toto.com", name: "toto", password: "VéRyComCET1DePQ55WD")
       // let registerJSON = try JSONEncoder().encode(registerReq)
        
        //let body = registerJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/register", registerReq){ res in
            XCTAssertNotNil(res)
            XCTAssertEqual(res.http.status.code , 400)
            let errorResp = try res.content.decode(ErrorDto.self).wait()
            XCTAssertTrue(errorResp.reason == "RegistrationError.invalidEmailFormat")
        }
    }
    

    func testLogin() throws {
        try testRegister()
        XCTAssertNoThrow(try login(withEmail: userIOS.email, password: userIOS.password, inside: app))
    }
    
    func testForgotPassword() throws {
        try testRegister()
        let forgot = ForgotPasswordDto(email: userIOS.email)
      //  let bodyJSON = try JSONEncoder().encode(forgot)
       // let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/forgotPassword", forgot){ res in
            print(res.content)
            XCTAssertEqual(res.http.status.code , 400)
            XCTAssertNotNil(res)
            let resp = try res.content.decode(ErrorDto.self).wait()
            XCTAssertTrue(resp.reason == "Contact an administrator to retrieve new password")
        }
    }
}

final class UsersControllerWhiteDomainsRegistrationTests: BaseAppTests {
    override func setUp() {
        var env = Environment.xcode
        env.arguments += ["-DregistrationWhiteDomains=[\"@toto.com\"]"]
        configure(with: env)
    }
    
    func testRegisterOK() throws{
        let registerReq = userIOS
       // let registerJSON = try JSONEncoder().encode(registerReq)
        
       // let body = registerJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/register", registerReq){ res in
            XCTAssertNotNil(res)
            XCTAssertEqual(res.http.status.code , 200)
        }
    }
    
    func testRegisterKO() throws{
        let registerReq = userANDROID
       // let registerJSON = try JSONEncoder().encode(registerReq)
        
       // let body = registerJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/register", registerReq){ res in
            XCTAssertNotNil(res)
            XCTAssertEqual(res.http.status.code , 400)
            let errorResp = try res.content.decode(ErrorDto.self).wait()
            XCTAssertTrue(errorResp.reason == "RegistrationError.emailDomainForbidden")
        }
    }
}


final class UsersControllerPasswordStrengthAndDelayRegistrationTests: BaseAppTests {
    override func setUp() {
        var env = Environment.xcode
        env.arguments += ["-DminimumPasswordStrength=4"]
        env.arguments += ["-DloginResponseDelay=10"]
        configure(with: env)
    }
    
    func testRegisterKO() throws{
        let registerReq = userIOS
      //  let registerJSON = try JSONEncoder().encode(registerReq)
        
     //   let body = registerJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/register", registerReq){ res in
            XCTAssertNotNil(res)
            XCTAssertEqual(res.http.status.code , 400)
            let errorResp = try res.content.decode(ErrorDto.self).wait()
            XCTAssertTrue(errorResp.reason == "UserError.invalidPassworsStrength")
        }
    }
    func testRegisterOK() throws{
        let registerReq = RegisterDto(email: "toto@toto.com", name: "toto", password: "VéRyComCET1DePQ55WD")
       // let registerJSON = try JSONEncoder().encode(registerReq)
        
       // let body = registerJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/register", registerReq){ res in
            XCTAssertNotNil(res)
            XCTAssertEqual(res.http.status.code , 200)
          //  let errorResp = try res.content.decode(ErrorDto.self).wait()
         //   XCTAssertTrue(errorResp.reason == "UserError.invalidPassworsStrength")
        }
    }
    
    func testLoginWithDelay() throws {
        try testRegisterOK()
        let start = Date()
        let registerUser = RegisterDto(email: "toto@toto.com", name: "toto", password: "VéRyComCET1DePQ55WD")
        XCTAssertNoThrow(try login(withEmail: registerUser.email, password: registerUser.password, inside: app))
        print("Delay \(start.timeIntervalSinceNow)")
        XCTAssertTrue(abs(start.timeIntervalSinceNow) >= 10)
    }
}

final class UsersControllerNoAutomaticAndTemplatesRegistrationTests: BaseAppTests {
    
    private func createTemplateFile()->String {
        let filename = "/tmp/test\(random(10))"
        XCTAssertTrue(FileManager.default.createFile(atPath:filename , contents:nil , attributes: nil))
        let file = FileHandle(forWritingAtPath: filename)
        let html =
            """
                <html><body><h1><a href="<%ACTIVATION_LINK%>">Activation Link"</a></h1></body></html>
            """
        file?.write(html.data(using: .utf8)!)
        
        return filename
    }

    
    override func setUp() {
        var env = Environment.xcode
        env.arguments += ["-DautomaticRegistration=false"]
       
        let smtpConfig = ["smtpServer":"gmail","smtpLogin":"toto","smtpPassword":"password","smtpSender":"toto","fakeMode":"true","alternateEmailtemplateFile":createTemplateFile(),"confirmationPath":"test/activation"]
        let stringValue = String(data:try! JSONEncoder().encode(smtpConfig), encoding: .utf8)!
        env.arguments += ["-DsmtpConfiguration=\(stringValue)"]
        configure(with: env)
    }
    
    func testRegisterAlternateTemplate() throws{
        let registerReq = userIOS
       // let registerJSON = try JSONEncoder().encode(registerReq)
        
       // let body = registerJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/register", registerReq){ res in
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
}

final class UsersControllerNoAutomaticRegistrationTests: BaseAppTests {
    override func setUp() {
        var env = Environment.xcode
        env.arguments += ["-DautomaticRegistration=false"]
        configure(with: env)
    }
    
    func testRegister() throws{
        let registerReq = userIOS
       // let registerJSON = try JSONEncoder().encode(registerReq)
        
       // let body = registerJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/register", registerReq){ res in
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
        try app.clientTest(.GET, "/v2/Users/activation?activationToken=\(user.activationToken!)"){ res in
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
        try app.clientTest(.GET, "/v2/Users/activation?activationToken=BadToken)"){ res in
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
        //let bodyJSON = try JSONEncoder().encode(login)
        
        //let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/login", login){ res in
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
     //   let bodyJSON = try JSONEncoder().encode(login)
        
     //   let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/login", login){ res in
            print(res.content)
            XCTAssertEqual(res.http.status.code , 200)
            XCTAssertNotNil(res)
            let loginResp = try res.content.decode(LoginRespDto.self).wait()
            XCTAssertTrue(loginResp.email == userIOS.email)
            XCTAssertTrue(loginResp.name == userIOS.name)
            XCTAssertNotNil(loginResp.token)
            XCTAssertNotNil(loginResp.refreshToken)
        }
    }
    
    func testLoginKo() throws {
        try testActivation()
        //login
        let login = LoginReqDto(email: userIOS.email, password: "bad password")
      //  let bodyJSON = try JSONEncoder().encode(login)
        
     //   let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/login", login){ res in
            print(res.content)
            XCTAssertEqual(res.http.status.code , 400)
            XCTAssertNotNil(res)
            let errorResp = try res.content.decode(ErrorDto.self).wait()
            XCTAssertTrue(errorResp.reason == "UserError.invalidLoginOrPassword")
        }
    }
    
    func testRefreshLogin() throws {
         try testActivation()
        let loginDto = try login(withEmail: userIOS.email, password: userIOS.password, inside: app)
        //refresh Login
        let login = RefreshTokenDto(email: userIOS.email, refreshToken: loginDto.refreshToken!)
      //  let bodyJSON = try JSONEncoder().encode(login)
        
      //  let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/refresh", login){ res in
            print(res.content)
            XCTAssertEqual(res.http.status.code , 200)
            XCTAssertNotNil(res)
            let loginResp = try res.content.decode(LoginRespDto.self).wait()
            XCTAssertTrue(loginResp.email == userIOS.email)
            XCTAssertTrue(loginResp.name == userIOS.name)
            XCTAssertNotNil(loginResp.token)
            XCTAssertNil(loginResp.refreshToken)
        }
    }
    
    func testRefreshLoginKOBadToken() throws {
         try testActivation()
        let loginDto = try login(withEmail: userIOS.email, password: userIOS.password, inside: app)
        //refresh Login
        let login = RefreshTokenDto(email: userIOS.email, refreshToken: "Bad Token")
        //let bodyJSON = try JSONEncoder().encode(login)
        
        //let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/refresh", login){ res in
            print(res.content)
            XCTAssertEqual(res.http.status.code , 401)
        }
    }
    
    func testRefreshLoginKOBadEmail() throws {
         try testActivation()
        let loginDto = try login(withEmail: userIOS.email, password: userIOS.password, inside: app)
        //refresh Login
        let login = RefreshTokenDto(email: "user@email.Com", refreshToken: loginDto.refreshToken!)
     //   let bodyJSON = try JSONEncoder().encode(login)
        
   //     let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/refresh", login){ res in
            print(res.content)
            XCTAssertEqual(res.http.status.code , 401)
        }
    }
    
    
    func testForgotPassword() throws {
        try testActivation()
        let forgot = ForgotPasswordDto(email: userIOS.email)
       // let bodyJSON = try JSONEncoder().encode(forgot)
       // let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/forgotPassword", forgot){ res in
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
       // let bodyJSON = try JSONEncoder().encode(login)
        
       // let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/login", login){ res in
            print(res.content)
            XCTAssertEqual(res.http.status.code , 400)
            let errorResp = try res.content.decode(ErrorDto.self).wait()
            XCTAssertTrue(errorResp.reason == "UserError.notActivated")
        }
    }
    
    func testForgotPasswordKO() throws {
        try testActivation()
        let forgot = ForgotPasswordDto(email: "john@Doe.com")
       // let bodyJSON = try JSONEncoder().encode(forgot)
       // let body = bodyJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/forgotPassword", forgot){ res in
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
    
    func testMeKOBadToken() throws {
        try testActivation()
        let loginResp = try login(withEmail: userIOS.email,password:userIOS.password,inside:app)
        XCTAssertNotNil(loginResp.token)
        let token = "Bad Token"
        let result = try app.clientSyncTest(.GET, "/v2/Users/me", token: token)
        XCTAssertEqual(result.http.status.code , 401)
    }
    
    func testMeKOWithRefreshToken() throws {
        try testActivation()
        let loginResp = try login(withEmail: userIOS.email,password:userIOS.password,inside:app)
        XCTAssertNotNil(loginResp.refreshToken)
        let token = loginResp.refreshToken!
        let result = try app.clientSyncTest(.GET, "/v2/Users/me", token: token)
        XCTAssertEqual(result.http.status.code , 401)
    }
    
    func testUpdate() throws {
        try testActivation()
        let loginResp = try login(withEmail: userIOS.email,password:userIOS.password,inside:app)
        let token = loginResp.token
        
        var me = try profile(with: token, inside: app)
        XCTAssertEqual(me.name, userIOS.name)
        XCTAssertEqual(me.favoritesApplicationsUUID,[])
        //XCTAssertNil(me.)
        let updateInfo = UpdateUserDto(name: "Foo Super User",favoritesApplicationsUUID:["XXX_XXX-XXX"])
        let updateResp = try app.clientSyncTest(.PUT, "/v2/Users/me", updateInfo , token: token)
        //check update resp
        let updatedMe = try updateResp.content.decode(UserDto.self).wait()
        XCTAssertEqual(updatedMe.name, updateInfo.name)
        XCTAssertEqual(updatedMe.favoritesApplicationsUUID, updateInfo.favoritesApplicationsUUID)
        
        //retrieve profile
        me = try profile(with: token, inside: app)
        //check "updated me"
        XCTAssertEqual(me.name, updateInfo.name)
        XCTAssertEqual(me.favoritesApplicationsUUID, updateInfo.favoritesApplicationsUUID)
        
        //delete app favorites
        let update2Info = UpdateUserDto(name: nil, password: nil,favoritesApplicationsUUID:[])
        let update2Resp = try app.clientSyncTest(.PUT, "/v2/Users/me", update2Info , token: token)
        let updated2Me = try update2Resp.content.decode(UserDto.self).wait()
        XCTAssertEqual(updated2Me.favoritesApplicationsUUID, [])
    }

    func testUpdatePassword() throws {
        try testActivation()
        let loginResp = try login(withEmail: userIOS.email,password:userIOS.password,inside:app)
        let token = loginResp.token

        //should failed without current password
        var updateInfo = UpdateUserDto(password:"new password")
        var httpResult = try app.clientSyncTest(.PUT, "/v2/Users/me", updateInfo , token: token)
        XCTAssertEqual(httpResult.http.status.code , 400)

        let newPassword = "new password"
        updateInfo = UpdateUserDto(password:newPassword,currentPassword:userIOS.password )
        httpResult = try app.clientSyncTest(.PUT, "/v2/Users/me", updateInfo , token: token)
        XCTAssertEqual(httpResult.http.status.code , 200)
        let _ = try httpResult.content.decode(UserDto.self).wait()

        //login with old password must failed
        XCTAssertThrowsError(try login(withEmail: userIOS.email,password:userIOS.password,inside:app))

        //login with new password
        _ = try login(withEmail: userIOS.email,password:newPassword,inside:app)
    }

    func testUpdatePasswordAsSysAdmin() throws {
        try testActivation()

        var environment = app.environment
        let configuration = try MdtConfiguration.loadConfig(from: nil, from: &environment)
        let loginResp = try login(withEmail: configuration.initialAdminEmail, password: configuration.initialAdminPassword, inside: app)
        let token = loginResp.token

        //should sucess without current password because sysadmin
        let newPassword = "new password"
        let updateInfo = UpdateUserDto(password:newPassword)
        let httpResult = try app.clientSyncTest(.PUT, "/v2/Users/me", updateInfo , token: token)
        XCTAssertEqual(httpResult.http.status.code , 200)
        let _ = try httpResult.content.decode(UserDto.self).wait()

        //login with old password must failed
        XCTAssertThrowsError(try login(withEmail: configuration.initialAdminEmail, password: configuration.initialAdminPassword, inside: app))

        //login with new password
        _ = try login(withEmail: configuration.initialAdminEmail,password:newPassword,inside:app)
    }
    
    func testUpdateWithApp() throws {
        try testActivation()
        var loginResp = try login(withEmail: userIOS.email,password:userIOS.password,inside:app)
        var token = loginResp.token
        try ApplicationsControllerTests.createApp(with: appDtoAndroid, inside: app, token: token)
        
        let me = try profile(with: token, inside: app)
        XCTAssertTrue(me.email == userIOS.email)
        XCTAssertTrue(me.administeredApplications.count == 1)
        
        //update Me : ex password
        let updateInfo = UpdateUserDto(name: nil,favoritesApplicationsUUID:nil)
        let updateResp = try app.clientSyncTest(.PUT, "/v2/Users/me", updateInfo , token: token)
        //check update resp
        let updatedMe = try updateResp.content.decode(UserDto.self).wait()
        XCTAssertEqual(updatedMe.name, userIOS.name)
        XCTAssertTrue(updatedMe.administeredApplications.count == 1)
    }
    
    func testUpdateNotAdmin() throws {
        try testActivation()
        let loginResp = try login(withEmail: userIOS.email,password:userIOS.password,inside:app)
        let token = loginResp.token
        
        let me = try profile(with: token, inside: app)
        
        let updateInfo = UpdateUserFullDto(name: "Foo Super User", favoritesApplicationsUUID:["XXX_XXX-XXX"],isActivated: !me.isActivated!,isSystemAdmin: !me.isSystemAdmin!)
        let updateResp = try app.clientSyncTest(.PUT, "/v2/Users/me", updateInfo , token: token)
        XCTAssertEqual(updateResp.http.status.code, 200)
        let updatedDto = try updateResp.content.decode(UserDto.self).wait()
        //check that isAdmin and Activated not changed
        XCTAssertEqual(updatedDto.isActivated,me.isActivated)
        XCTAssertEqual(updatedDto.isSystemAdmin,me.isSystemAdmin)
    }
    
    func testUpdateOther() throws {
        try testActivation()
        let loginResp = try login(withEmail: userIOS.email,password:userIOS.password,inside:app)
        let token = loginResp.token
        
        //test update without be a admin
        let updateInfo = UpdateUserFullDto(name: "Foo Super User", password: "azerty",favoritesApplicationsUUID:["XXX_XXX-XXX"],isActivated: false,isSystemAdmin: true)
        var updateResp = try app.clientSyncTest(.PUT, "/v2/Users/\(userIOS.email)", updateInfo , token: token)
        XCTAssertEqual(updateResp.http.status.code, 401)
        //check update resp

        var environment = app.environment
        let configuration = try MdtConfiguration.loadConfig(from: nil, from: &environment)
        let adminToken = try login(withEmail: configuration.initialAdminEmail, password: configuration.initialAdminPassword, inside: app).token
        //retry as admin
        updateResp = try app.clientSyncTest(.PUT, "/v2/Users/\(userIOS.email)", updateInfo, token: adminToken)
        XCTAssertEqual(updateResp.http.status.code, 200)
        let updatedDto = try updateResp.content.decode(UserDto.self).wait()
        XCTAssertEqual(updatedDto.name,updateInfo.name)
        XCTAssertEqual(updatedDto.isActivated,updateInfo.isActivated)
        XCTAssertEqual(updatedDto.isSystemAdmin,updateInfo.isSystemAdmin)
    }
    
    func testUpdateDelete() throws {
        try testActivation()
        let loginResp = try login(withEmail: userIOS.email,password:userIOS.password,inside:app)
        let token = loginResp.token
        //test update without be a admin
        var deleteResp = try app.clientSyncTest(.DELETE, "/v2/Users/\(userIOS.email)" , token: token)
        XCTAssertEqual(deleteResp.http.status.code, 401)

        var environment = app.environment
        let configuration = try MdtConfiguration.loadConfig(from: nil, from: &environment)
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
 //   let bodyJSON = try JSONEncoder().encode(login)
  //  let body = bodyJSON.convertToHTTPBody()
    let result = try app.clientSyncTest(.POST, "/v2/Users/login", login)
    return try result.content.decode(LoginRespDto.self).wait()
}

func register(registerInfo:RegisterDto, inside app:Application) throws -> UserDto {
    //register
  //  let bodyJSON = try JSONEncoder().encode(registerInfo)
  //  let body = bodyJSON.convertToHTTPBody()
    let result = try app.clientSyncTest(.POST, "/v2/Users/register", registerInfo)
    return try result.content.decode(UserDto.self).wait()
}
