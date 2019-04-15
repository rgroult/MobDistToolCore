//
//  ApplicationsController.swift
//  App
//
//  Created by Rémi Groult on 20/02/2019.
//

import Foundation
import Vapor
import Routing
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
        let uuid = try req.parameters.next(UUID.self)
        let context = try req.context()
        return try retrieveUser(from:req)
            .flatMap{user -> Future<ApplicationDto> in
                guard let user = user else { throw Abort(.unauthorized)}
                return try req.content.decode(ApplicationUpdateDto.self)
                    .flatMap({ applicationUpdateDto in
                        return try findApplication(uuid: uuid.uuidString, into: context)
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
    
    func applications(_ req: Request) throws -> Future<[ApplicationSummaryDto]> {
        let platformFilter:Platform?
        if let queryPlaform = try? req.query.get(String.self, at: "platform") {
            if let platform = Platform(rawValue: queryPlaform)  {
                platformFilter = platform
            }else {
                throw ApplicationError.unknownPlatform
            }
        }else {
            platformFilter = nil
        }
        return try retrieveUser(from:req)
            .flatMap{user in
                guard let _ = user else { throw Abort(.unauthorized)}
                let context = try req.context()
                return try findApplications(platform: platformFilter, into: context)
                    .map(transform: {ApplicationSummaryDto(from: $0)})
                    .getAllResults()
                
                /*
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
                 }*/
                
        }
    }
    
    func applicationDetail(_ req: Request) throws -> Future<ApplicationDto> {
        let uuid = try req.parameters.next(UUID.self)
        return try retrieveUser(from:req)
            .flatMap{user in
                guard let user = user else { throw Abort(.unauthorized)}
                let context = try req.context()
                return try findApplication(uuid: uuid.uuidString, into: context)
                    .flatMap({ app in
                        guard let app = app else { throw ApplicationError.notFound }
                        return ApplicationDto.create(from: app, content:app.isAdmin(user: user) ? .full : .light , in : context)
                    })}
    }
    
    // @ApiMethod(method: 'DELETE', path: 'app/{appId}')
    func deleteApplication(_ req: Request) throws -> Future<MessageDto> {
        return try findApplicationInfo(from:req, needAdmin: true)
            .flatMap({ info  in
                let context = try req.context()
                return App.deleteApplication(by: info.app, into: context).map {
                    return MessageDto(message: "Application Deleted")
                }
            })
    }
    
    //@ApiMethod(method: 'PUT', path: 'app/{appId}/adminUsers/{email}')
    func addAdminUser(_ req: Request) throws -> Future<MessageDto> {
        return try findApplicationInfo(from:req, needAdmin: true)
            .flatMap({ info  in
                let email = try req.parameters.next(String.self)
                let context = try req.context()
                //find user with email
                return try findUser(by: email, into: context)
                    .flatMap({user in
                        guard let user = user else { throw ApplicationError.invalidApplicationAdministrator }
                        return try info.app.addAdmin(user: user, into: context)
                            .map{ _ in MessageDto(message: "Admin User Added") }
                })
        })
    }
    
    //@ApiMethod(method: 'DELETE', path: 'app/{appId}/adminUsers/{email}')
    func deleteAdminUser(_ req: Request) throws -> Future<MessageDto> {
        return try findApplicationInfo(from:req, needAdmin: true)
            .flatMap({ info  in
                let email = try req.parameters.next(String.self)
                let context = try req.context()
                //find user with email
                return try findUser(by: email, into: context)
                    .flatMap({user in
                        guard let user = user else { throw ApplicationError.invalidApplicationAdministrator }
                        guard info.app.adminUsers.count > 1 else { throw ApplicationError.deleteLastApplicationAdministrator }
                        return try info.app.removeAdmin(user: user, into: context)
                            .map{ _ in MessageDto(message: "Admin User Added") }
                    })
            })
    }
    
    //@ApiMethod(method: 'GET', path: 'app/{appId}/versions?pageIndex=1&limitPerPage=30&branch=master')
    func getApplicationVersions(_ req: Request) throws -> Future<[ArtifactDto]> {
        let pageIndex = try? req.query.get(Int.self, at: "pageIndex")
        let limitPerPage = try? req.query.get(Int.self, at: "limitPerPage")
        let selectedBranch = try? req.query.get(String.self, at: "branch")
        
        throw "Not implemented"
    }
    
    //@ApiMethod(method: 'GET', path: 'app/{appId}/versions/last')
    func getApplicationLastVersions(_ req: Request) throws -> Future<[ArtifactDto]> {
        throw "Not implemented"
    }
    
    private func findApplicationInfo(from req: Request, needAdmin:Bool) throws -> Future<(user:User,app:MDTApplication)>{
        let uuid = try req.parameters.next(UUID.self)
        return try retrieveUser(from:req)
            .flatMap({ user in
                guard let user = user else { throw Abort(.unauthorized)}
                let context = try req.context()
                return try App.findApplication(uuid: uuid.uuidString, into: context)
                    .map({ app in
                        guard let app = app else { throw ApplicationError.notFound }
                        if needAdmin {
                            guard app.isAdmin(user: user)  else { throw Abort(ApplicationError.notAnApplicationAdministrator)}
                        }
                        return (user,app)
                })
            })
    }
}
