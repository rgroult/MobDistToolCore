//
//  ApplicationsController.swift
//  App
//
//  Created by Rémi Groult on 20/02/2019.
//

import Foundation
import Vapor
import Swiftgger
import Meow

final class ApplicationsController:BaseController {
    
    init(apiBuilder:OpenAPIBuilder) {
        super.init(version: "v2", pathPrefix: "Applications", apiBuilder: apiBuilder)
    }
    
    func createApplication(_ req: Request) throws -> Future<ApplicationDto> {
        let context = try req.context()
        return try retrieveUser(from:req)
            .flatMap{user -> Future<ApplicationDto> in
                guard let user = user else { throw Abort(.unauthorized)}
                return try req.content.decode(ApplicationCreateDto.self)
                    .flatMap{  appDto -> Future<MDTApplication> in
                        return try App.createApplication(name: appDto.name, platform: appDto.platform, description: appDto.description, adminUser: user,base64Icon:appDto.base64IconData, into: context)
                    }
                    .flatMap({ app -> Future<ApplicationDto>  in
                        App.updateApplication(from: app, maxVersionCheckEnabled: nil, iconData: nil)
                        return app.save(to: context).flatMap{ ApplicationDto.create(from: app, content: .full, in : context)}
                    })
        }
    }
    
    func updateApplication(_ req: Request) throws -> Future<ApplicationDto> {
        let uuid = try req.parameters.next(String.self)
        let context = try req.context()
        return try retrieveUser(from:req)
            .flatMap{user -> Future<ApplicationDto> in
                guard let user = user else { throw Abort(.unauthorized)}
                return try req.content.decode(ApplicationUpdateDto.self)
                    .flatMap({ applicationUpdateDto in
                        return try findApplication(uuid: uuid, into: context)
                            .flatMap({ app  in
                                guard let app = app else {throw ApplicationError.notFound }
                                //check if user is app admin
                                guard app.isAdmin(user: user) else { throw ApplicationError.notAnApplicationAdministrator }
                                App.updateApplication(from: app, with: applicationUpdateDto)
                                return saveApplication(app: app, into: context)
                                    .flatMap { ApplicationDto.create(from: $0, content: .full, in : context) }
                            })
                    })
        }
    }
    
    func applications(_ req: Request) throws -> Future<[ApplicationDto]> {
        var platformFilter:Platform?
        if let platormString = try? req.query.get(String.self, at: "platorm") {
            platformFilter = try Platform.create(from: platormString)
        }
        
        return try retrieveUser(from:req)
            .flatMap{user in
                guard let user = user else { throw Abort(.unauthorized)}
                return req.meow().flatMap({ context -> Future<[ApplicationDto]> in
                    let query:Query
                    if let platorm = platformFilter {
                        query = Query.valEquals(field: "platform", val: platorm.rawValue)
                    }else {
                        query = Query()
                    }
                    return context.find(MDTApplication.self,where:query)
                        .map(transform: { app  in
                            return ApplicationDto.create(from: app, content:app.isAdmin(user: user) ? .full : .light , in : context)
                        })
                        .getAllResults()
                        .flatMap {elements ->  Future<[ApplicationDto]> in
                            return elements.flatten(on: context)
                    }
                })
        }
    }
}
