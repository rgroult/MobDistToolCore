//
//  File.swift
//  
//
//  Created by Remi Groult on 15/10/2021.
//

import Foundation
@testable import App

public func profile(with token:String,inside app:Application) throws -> UserDto {
    let result = try app.clientSyncTest(.GET, "/v2/Users/me", token: token)
    return try result.content.decode(UserDto.self).wait()
}

public func login(withEmail:String, password:String,inside app:Application) throws -> LoginRespDto {
    //login
    let login = LoginReqDto(email:withEmail, password: password)
 //   let bodyJSON = try JSONEncoder().encode(login)
  //  let body = bodyJSON.convertToHTTPBody()
    let result = try app.clientSyncTest(.POST, "/v2/Users/login", login)
    return try result.content.decode(LoginRespDto.self).wait()
}

public func register(registerInfo:RegisterDto, inside app:Application) throws -> UserDto {
    //register
  //  let bodyJSON = try JSONEncoder().encode(registerInfo)
  //  let body = bodyJSON.convertToHTTPBody()
    let result = try app.clientSyncTest(.POST, "/v2/Users/register", registerInfo)
    return try result.content.decode(UserDto.self).wait()
}
