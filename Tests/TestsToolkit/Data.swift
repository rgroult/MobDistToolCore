//
//  File.swift
//  
//
//  Created by Remi Groult on 15/10/2021.
//

import Foundation
import Vapor
@testable import App

public let appDtoiOS = ApplicationCreateDto(name: "testAppiOS", platform: Platform.ios, description: "bla bla", base64IconData: nil, enableMaxVersionCheck:  nil)
public let appDtoAndroid = ApplicationCreateDto(name: "test App Android", platform: Platform.android, description: "bla bla", base64IconData: nil, enableMaxVersionCheck:  nil)

public let userIOS = RegisterDto(email: "toto@toto.com", name: "toto", password: "passwd")
public let userANDROID = RegisterDto(email: "titi@titi.com", name: "titi", password: "passwd")

public let ipaContentType = HTTPMediaType(type: "application", subType: "octet-stream ipa")
public let apkContentType = HTTPMediaType.fileExtension("apk")!
