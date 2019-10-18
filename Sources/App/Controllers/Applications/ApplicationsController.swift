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
import Pagination

final class ApplicationsController:BaseController {
    private let externalUrl:URL
    let sortFields = ["created": "createdAt", "name" : "name"]
    
    init(apiBuilder:OpenAPIBuilder,externalUrl:URL) {
        self.externalUrl = externalUrl.appendingPathComponent("v2/Applications")
        super.init(version: "v2", pathPrefix: "Applications", apiBuilder: apiBuilder)
    }
    
    func createApplication(_ req: Request) throws -> Future<ApplicationDto> {
        let context = try req.context()
        let serverUrl = externalUrl
        return try retrieveUser(from:req)
            .flatMap{user -> Future<ApplicationDto> in
                guard let user = user else { throw Abort(.unauthorized)}
                return try req.content.decode(ApplicationCreateDto.self)
                    .flatMap{  appDto -> Future<MDTApplication> in
                        return try App.createApplication(name: appDto.name, platform: appDto.platform, description: appDto.description, adminUser: user,base64Icon:appDto.base64IconData, into: context)
                    }
                    .flatMap({ app -> Future<ApplicationDto>  in
                        App.updateApplication(from: app, maxVersionCheckEnabled: nil, iconData: nil)
                        return saveApplication(app: app, into: context)
                            .flatMap{ ApplicationDto.create(from: $0, content: .full, in : context)}
                            .map{$0.setIconUrl(url: app.generateIconUrl(externalUrl: serverUrl))}
                    })
        }
    }
    
    func updateApplication(_ req: Request) throws -> Future<ApplicationDto> {
        let appUuid = try req.parameters.next(String.self)
        let context = try req.context()
        let serverUrl = externalUrl
        return try retrieveUser(from:req)
            .flatMap{user -> Future<ApplicationDto> in
                guard let user = user else { throw Abort(.unauthorized)}
                return try req.content.decode(ApplicationUpdateDto.self)
                    .flatMap({ applicationUpdateDto in
                        return try findApplication(uuid: appUuid, into: context)
                            .flatMap({ app  in
                                guard let app = app else {throw ApplicationError.notFound }
                                //check if user is app admin
                                guard app.isAdmin(user: user) else { throw ApplicationError.notAnApplicationAdministrator }
                                App.updateApplication(from: app, with: applicationUpdateDto)
                                return saveApplication(app: app, into: context)
                                    .flatMap {ApplicationDto.create(from: $0, content: .full, in : context)}
                                    .map{$0.setIconUrl(url: app.generateIconUrl(externalUrl: serverUrl))}
                            })
                    })
        }
    }
    
    func iconApplication(_ req: Request) throws -> Future<ImageDto> {
        //   throw "not implemented"
        let appUuid = try req.parameters.next(String.self)
        let context = try req.context()
        return try findApplication(uuid: appUuid, into: context)
            .flatMap{ app -> Future<ImageDto?> in
                guard let base64 = app?.base64IconData else { throw ApplicationError.iconNotFound }
                // guard let icon =  ImageDto(from: base64) else { throw ApplicationError.invalidIconFormat}
                // return icon
                return ImageDto.create(for: req, base64Image: base64)
            }.map{ image -> ImageDto in
                guard let image = image else { throw ApplicationError.invalidIconFormat}
                return image
        }
    }
    
    func applications(_ req: Request) throws -> Future<Paginated<ApplicationSummaryDto>> {
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
        let serverUrl = externalUrl
        return try retrieveMandatoryUser(from:req)
            .flatMap{[weak self]user in
                guard let `self` = self else { throw Abort(.internalServerError)}
                let context = try req.context()
                let (queryUse,appFounds) = try findApplications(platform: platformFilter, into: context,additionalQuery:self.extractSearch(from: req, searchField: "name"))
                return appFounds.map(transform: {ApplicationSummaryDto(from: $0).setIconUrl(url: $0.generateIconUrl(externalUrl: serverUrl))})
                    .paginate(for: req, sortFields: self.sortFields,findQuery: queryUse)
                /*return try findApplications(platform: platformFilter, into: context)
                    .map(transform: {ApplicationSummaryDto(from: $0).setIconUrl(url: $0.generateIconUrl(externalUrl: serverUrl))})
                    .getAllResults()*/
        }
    }
    
    func applicationDetail(_ req: Request) throws -> Future<ApplicationDto> {
        let appUuid = try req.parameters.next(String.self)
        let serverUrl = externalUrl
        return try retrieveUser(from:req)
            .flatMap{user in
                guard let user = user else { throw Abort(.unauthorized)}
                let context = try req.context()
                return try findApplication(uuid: appUuid, into: context)
                    .flatMap({ app in
                        guard let app = app else { throw ApplicationError.notFound }
                        return ApplicationDto.create(from: app, content:app.isAdmin(user: user) ? .full : .light , in : context)
                        .map{$0.setIconUrl(url: app.generateIconUrl(externalUrl: serverUrl))}
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
    
    func getApplicationVersionsWithParameters(_ req: Request,uuid:String,pageIndex:Int?,limitPerPage:Int?,selectedBranch:String?,isLatestBranch:Bool = false) throws -> Future<[ArtifactDto]> {
        let context = try req.context()
        return try retrieveUser(from:req)
            .flatMap{ user in
                guard let _ = user else { throw Abort(.unauthorized)}
                return try App.findApplication(uuid: uuid, into: context)
            }
            .flatMap{ (app:MDTApplication?) -> Future<[ArtifactDto]> in
                guard let app = app else { throw ApplicationError.notFound }
                let excludedBranch = isLatestBranch ? nil : lastVersionBranchName
                return try findArtifacts(app: app, pageIndex: pageIndex, limitPerPage: limitPerPage, selectedBranch:selectedBranch, excludedBranch: excludedBranch , into: context)
                    .map(transform: {ArtifactDto(from: $0)})
                    .getAllResults()
        }
    }
    
    //@ApiMethod(method: 'GET', path: 'app/{appId}/versions?pageIndex=1&limitPerPage=30&branch=master')
    func getApplicationVersions(_ req: Request) throws -> Future<[ArtifactDto]> {
        let uuid = try req.parameters.next(String.self)
        //parameters
        let pageIndex = try? req.query.get(Int.self, at: "pageIndex")
        let limitPerPage = try? req.query.get(Int.self, at: "limitPerPage")
        let selectedBranch = try? req.query.get(String.self, at: "branch")
        
        return try getApplicationVersionsWithParameters(req, uuid:uuid , pageIndex: pageIndex, limitPerPage: limitPerPage, selectedBranch: selectedBranch, isLatestBranch: false)
    }
    
    //@ApiMethod(method: 'GET', path: 'app/{appId}/versions/last')
    func getApplicationLastVersions(_ req: Request) throws -> Future<[ArtifactDto]> {
        let uuid = try req.parameters.next(String.self)
        
        return try getApplicationVersionsWithParameters(req, uuid:uuid , pageIndex: nil, limitPerPage: nil, selectedBranch: lastVersionBranchName, isLatestBranch: true)
    }
    
    //@ApiMethod(method: 'GET', path: 'app/{appId}/icon')
    
    private func findApplicationInfo(from req: Request, needAdmin:Bool) throws -> Future<(user:User,app:MDTApplication)>{
        let uuid = try req.parameters.next(String.self)
        return try retrieveUser(from:req)
            .flatMap({ user in
                guard let user = user else { throw Abort(.unauthorized)}
                let context = try req.context()
                return try App.findApplication(uuid: uuid, into: context)
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
