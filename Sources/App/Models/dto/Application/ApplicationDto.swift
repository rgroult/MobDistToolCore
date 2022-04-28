//
//  ApplicationDto.swift
//  App
//
//  Created by Rémi Groult on 19/02/2019.
//

import Foundation
import Vapor
import Meow

struct ApplicationDto: Codable {
    var name:String
    var platform:Platform
    var description:String
    var uuid:String
    var adminUsers: [UserDto]
    var availableBranches:[String]
    //admin fields
    var permanentLinks:[PermanentLinkDto]?
    var apiKey:String?
    var maxVersionSecretKey:String?
    var iconUrl:String? = nil
    var createdDate:Date
}

extension ApplicationDto {
    static func sample() -> ApplicationDto {
        return ApplicationDto( name: "Awesome App", platform:.ios ,description:"",uuid:"dsfdsfdsf",adminUsers:[], availableBranches:["release","develop","master"],apiKey:"SQDQSDCQD",maxVersionSecretKey:"ùmlùlmjlsdlf", iconUrl:nil,createdDate: Date())
    }

    static func create(from app:MDTApplication, content:ModelVisibility, urlCreator:@escaping ((String) -> (installUrl:String,installPageUrl:String)), in context: Meow.MeowDatabase) -> EventLoopFuture<ApplicationDto>{
        var appDto = ApplicationDto(from: app, content:content)
        
        return app.adminUsers
            .map { $0.resolve(in: context) }.flatten(on: context.eventLoop)
            .and(findDistinctsBranches(app: app, into: context).flatMapError{ _ in context.eventLoop.makeSucceededFuture([])})
            .and(content == .light ? context.eventLoop.makeSucceededFuture([]) : retrievePermanentLinks(app: app, into: context).flatMapError{ _ in context.eventLoop.makeSucceededFuture([])})
            .map({ (arg0 , linksInfo) in
                let (users, branches) = arg0
                appDto.adminUsers = users.map{UserDto.create(from: $0, content: .light)}
                appDto.availableBranches = branches
                appDto.permanentLinks = content == .light ? nil : linksInfo.map{ info in
                    let (installUrl, installPageUrl) = urlCreator(info.tokenId)
                    return PermanentLinkDto(uuid: info.tokenId, from: info.link, artifact: info.artifact, installUrl: installUrl, installPageUrl: installPageUrl) }
                //appDto.permanentLinks = content == .light ? nil : tokensInfo.map{ PermanentLinkDto(from: $0)}.compactMap{ $0} //only as admin
                return appDto
            })
    }
    
    private init(from app:MDTApplication, content:ModelVisibility){
        name = app.name
        description = app.description
        platform = app.platform
        uuid = app.uuid
        adminUsers = []
        availableBranches = []
        if content == .full {
            apiKey = app.apiKey
            maxVersionSecretKey = app.maxVersionSecretKey
        }
        createdDate = app.createdAt
    }
    
    func setIconUrl(url:String?) -> ApplicationDto {
        var result = self
        result.iconUrl = url
        return result
    }
}

extension ApplicationDto : Content {}



