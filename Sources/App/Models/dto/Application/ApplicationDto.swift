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
    var apiKey:String?
    var maxVersionSecretKey:String?
    var iconUrl:String? = nil
    var createdDate:Date
}

extension ApplicationDto {
    static func sample() -> ApplicationDto {
        return ApplicationDto( name: "Awesome App", platform:.ios ,description:"",uuid:"dsfdsfdsf",adminUsers:[], availableBranches:["release","develop","master"],apiKey:"SQDQSDCQD",maxVersionSecretKey:"ùmlùlmjlsdlf", iconUrl:nil,createdDate: Date())
    }

    static func create(from app:MDTApplication, content:ModelVisibility, in context: Context) -> Future<ApplicationDto>{
        var appDto = ApplicationDto(from: app, content:content)
        
        return app.adminUsers
            .map { $0.resolve(in: context) }
            .flatten(on: context)
            .and(findDistinctsBranches(app: app, into: context).mapIfError{ _ in []})
            .map{ users,branches in
                appDto.adminUsers = users.map{UserDto.create(from: $0, content: .light)}
                appDto.availableBranches = branches
                return appDto
            }
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



