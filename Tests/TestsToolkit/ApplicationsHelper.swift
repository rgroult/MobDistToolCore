//
//  File.swift
//  
//
//  Created by Remi Groult on 15/10/2021.
//

import Foundation
import XCTest
@testable import App

public func createApp(with info:ApplicationCreateDto, inside app:Application,token:String?) throws -> ApplicationDto {
    //let body = try info.convertToHTTPBody()
    let result = try app.clientSyncTest(.POST, "/v2/Applications", info,token:token)
    print(result.content)
    return try result.content.decode(ApplicationDto.self).wait()
}
public func populateApplications(nbre:Int,tempo:Double = 0,inside app:Application,token:String) throws{
    for i in 1...nbre {
        if tempo > 0.0 {
            Thread.sleep(forTimeInterval: tempo)
        }
        let platform = i%2 == 0 ? Platform.android : Platform.ios
        let appDto = ApplicationCreateDto(name: "Application\(String(format: "%03d",i))", platform: platform, description: "Desc App", base64IconData: nil, enableMaxVersionCheck: nil)
        _ = try createApp(with: appDto, inside: app, token: token)
    }
}


public func createPermanentLink(appUUID:String, branch:String, name:String, validity:Int,inside app:Application,token:String?) throws -> PermanentLinkDto{
    let linkDto = PermanentLinkCreateDto(daysValidity:validity,branch:branch,artifactName:name)
    
    let result = try app.clientSyncTest(.POST, "/v2/Applications/\(appUUID)/links", linkDto,token: token)
    return try result.content.decode(PermanentLinkDto.self).wait()
}

public func deletePermanentLink(appUUID:String, permanentLinkId:String, inside app:Application,token:String?) throws -> MessageDto{
    let result = try app.clientSyncTest(.DELETE, "/v2/Applications/\(appUUID)/links?token=\(permanentLinkId)",token: token)
    XCTAssertEqual(result.http.status.code, 200)
    return try result.content.decode(MessageDto.self).wait()
}

public func getPermanentLinks(appUUID:String,inside app:Application,token:String?) throws -> [PermanentLinkDto]{
    let result = try app.clientSyncTest(.GET, "/v2/Applications/\(appUUID)/links",token: token)
    return try result.content.decode([PermanentLinkDto].self).wait()
}


public func applicationDetail(appUUID:String,inside app:Application,token:String?) throws -> ApplicationDto{
    let result = try app.clientSyncTest(.GET, "/v2/Applications/\(appUUID)",token: token)
    return try result.content.decode(ApplicationDto.self).wait()
}
