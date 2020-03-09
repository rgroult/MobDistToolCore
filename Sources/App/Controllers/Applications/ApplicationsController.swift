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
    let artifactsSortFields = ["created": "createdAt", "version" : "sortIdentifier"]
    let groupedArtifactsSortFields = ["created": "date", "version" : "_id.sortIdentifier"]
    let artifactController = ArtifactsController(apiBuilder: nil)
    
    init(apiBuilder:OpenAPIBuilder,externalUrl:URL) {
        if !BaseController.basePathPrefix.isEmpty{
            //fix for swift on linux which crash with appendingPathComponent("")
            self.externalUrl = externalUrl.appendingPathComponent(BaseController.basePathPrefix).appendingPathComponent("v2/Applications")
        }else {
            self.externalUrl = externalUrl.appendingPathComponent("v2/Applications")
        }
        
        super.init(version: "v2", pathPrefix: "Applications", apiBuilder: apiBuilder)
    }
    
    func createApplication(_ req: Request) throws -> Future<ApplicationDto> {
        let context = try req.context()
        let serverUrl = externalUrl
        return try retrieveUser(from:req)
            .flatMap{user -> Future<ApplicationDto> in
                guard let user = user else { throw Abort(.unauthorized)}
                return try req.content.decode(ApplicationCreateDto.self)
                    .flatMap{  appDto -> Future<ApplicationDto> in
                        return try App.createApplication(name: appDto.name, platform: appDto.platform, description: appDto.description, adminUser: user,base64Icon:appDto.base64IconData,maxVersionCheckEnabled:appDto.enableMaxVersionCheck, into: context)
                        .flatMap{app in
                            ApplicationDto.create(from: app, content: .full, in : context)
                            .map{$0.setIconUrl(url: app.generateIconUrl(externalUrl: serverUrl))}
                            .do({ [weak self] dto in self?.track(event: .CreateApp(app: app, user: user), for: req)})
                        }
                        
                            /*
                        .flatMap({ app -> Future<ApplicationDto>  in
                            App.updateApplication(from: app, maxVersionCheckEnabled: nil, iconData: nil)
                            return saveApplication(app: app, into: context)
                                .flatMap{ ApplicationDto.create(from: $0, content: .full, in : context)}
                                .map{$0.setIconUrl(url: app.generateIconUrl(externalUrl: serverUrl))}
                                .do({ [weak self] dto in self?.track(event: .CreateApp(app: app, user: user), for: req)})
                            /*  .map {[weak self] dto in
                             self?.track(event: .CreateApp(app: app, user: user), for: req)
                             return dto}*/
                        })*/
                }
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
                                return try App.updateApplicationWithParameters(from: app, name: applicationUpdateDto.name, description: applicationUpdateDto.description, maxVersionCheckEnabled: applicationUpdateDto.maxVersionCheckEnabled, iconData: applicationUpdateDto.base64IconData, into: context)
                                .flatMap {ApplicationDto.create(from: $0, content: .full, in : context)}
                                .map{$0.setIconUrl(url: app.generateIconUrl(externalUrl: serverUrl))}
                                .do({ [weak self] dto in self?.track(event: .UpdateApp(app: app, user: user), for: req)})
                                
                              /*  App.updateApplication(from: app, with: applicationUpdateDto)
                                return saveApplication(app: app, into: context)
                                    .flatMap {ApplicationDto.create(from: $0, content: .full, in : context)}
                                    .map{$0.setIconUrl(url: app.generateIconUrl(externalUrl: serverUrl))}
                                    .do({ [weak self] dto in self?.track(event: .UpdateApp(app: app, user: user), for: req)})*/
                            })
                    })
        }
    }
    
    func iconApplication(_ req: Request) throws -> Future<ImageDto> {
        //   throw "not implemented"
        let appUuid = try req.parameters.next(String.self)
        let context = try req.context()
        return try findApplication(uuid: appUuid, into: context)
            .flatMap{ app -> Future<ImageDto> in
                guard let base64 = app?.base64IconData else { throw ApplicationError.iconNotFound }
                // guard let icon =  ImageDto(from: base64) else { throw ApplicationError.invalidIconFormat}
                // return icon
                return ImageDto.create(for: req, base64Image: base64)
                    .map{ image -> ImageDto in
                        guard let image = image else {
                            //invalid icon format, erase it
                            if let app = app {
                                _ = try updateApplicationWithParameters(from: app, name: nil, description: nil, maxVersionCheckEnabled: nil, iconData: "", into: context)
                            }
                            throw ApplicationError.invalidIconFormat}
                        return image
                }
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
        return try retrieveMandatoryUser(from:req)
            .flatMap{[weak self]user in
                guard let `self` = self else { throw Abort(.internalServerError)}
                let context = try req.context()
                let (queryUse,appFounds) = try findApplications(platform: platformFilter, into: context,additionalQuery:self.extractSearch(from: req, searchField: "name"))
                return appFounds.map(transform: {self.generateSummaryDto(from:$0)})
                //return appFounds.map(transform: {ApplicationSummaryDto(from: $0).setIconUrl(url: $0.generateIconUrl(externalUrl: serverUrl))})
                    .paginate(for: req, sortFields: self.sortFields,defaultSort: "created", findQuery: queryUse)
                /*return try findApplications(platform: platformFilter, into: context)
                 .map(transform: {ApplicationSummaryDto(from: $0).setIconUrl(url: $0.generateIconUrl(externalUrl: serverUrl))})
                 .getAllResults()*/
        }
    }
    
    func generateSummaryDto(from app:MDTApplication) -> ApplicationSummaryDto {
        return ApplicationSummaryDto(from: app).setIconUrl(url: app.generateIconUrl(externalUrl: externalUrl))
    }
    
    func applicationsFavorites(_ req: Request) throws -> Future<[ApplicationSummaryDto]> {
        let serverUrl = externalUrl
        return try retrieveMandatoryUser(from:req)
            .flatMap{user in
                // guard let `self` = self else { throw Abort(.internalServerError)}
                let context = try req.context()
                return try findApplications(with: UserDto.generateFavorites(from: user.favoritesApplicationsUUID), into: context)
                    .map(transform: {ApplicationSummaryDto(from: $0).setIconUrl(url: $0.generateIconUrl(externalUrl: serverUrl))})
                    .getAllResults()
        }
    }
    
    private func retrieveUserAndApp(_ req: Request, appUuid:String,needToBeAdmin:Bool) throws -> Future<(User,MDTApplication)> {
        let context = try req.context()
        return try retrieveUser(from:req)
            .flatMap{user in
                guard let user = user else { throw Abort(.unauthorized)}
                return try findApplication(uuid: appUuid, into: context)
                    .map({ app  in
                        guard let app = app else {throw ApplicationError.notFound }
                        if needToBeAdmin {
                            guard app.isAdmin(user: user) else { throw ApplicationError.notAnApplicationAdministrator }
                        }
                        return (user,app)
                    })
        }
    }
    
    private func generatePermanentLink(token:MDTApplication.TokenLink,artifact:Artifact?,platform:Platform) throws -> PermanentLinkDto {
        let (installUrl,intallPage) = try generateUrls(with: token, platform: platform)
        return PermanentLinkDto(from: token.link, artifact: artifact, installUrl: installUrl, installPageUrl: intallPage)
    }
    
    //GET /<uuid>/link
    func applicationPermanentLinks(_ req: Request) throws -> Future<[PermanentLinkDto]> {
        let appUuid = try req.parameters.next(String.self)
        
        return try retrieveUserAndApp(req, appUuid: appUuid, needToBeAdmin: true)
            .flatMap { (user, app) in
                let context = try req.context()
                return try retrievePermanentLinks(app: app, into: context)
                    .map{ permanentLinkInfoList throws -> [PermanentLinkDto] in
                        return try permanentLinkInfoList.map {[weak self] permanentLinkInfo throws in
                            guard let `self` = self else { throw Abort(.internalServerError)}
                            let  (token, artifact)  = permanentLinkInfo
                            let (installUrl,intallPage) = try self.generateUrls(with: token, platform: app.platform)
                            return PermanentLinkDto(from: token.link, artifact: artifact, installUrl: installUrl, installPageUrl: intallPage)
                        }
                }
        }
        
    }
    
    //POST /<uuid>/link
    func createApplicationPermanentLink(_ req: Request) throws -> Future<PermanentLinkDto> {
        let appUuid = try req.parameters.next(String.self)
        
        return try retrieveUserAndApp(req, appUuid: appUuid, needToBeAdmin: true)
            .flatMap { (user, app) in
                let context = try req.context()
                return try req.content.decode(PermanentLinkCreateDto.self)
                    .flatMap{ linkCreateDto in
                        let link = MDTApplication.PermanentLink(applicationUuid: appUuid, branch: linkCreateDto.branch, artifactName: linkCreateDto.artifactName, validity: linkCreateDto.daysValidity)
                        return try App.generatePermanentLink(with: link, into: context)
                            .flatMap{ tokenInfo in
                                let tokenLink = MDTApplication.TokenLink(tokenId: tokenInfo.uuid, application: app, link: link)
                                //throw "not implemented"
                                
                                return try retrievePermanentLinkArtifact(token: tokenLink, into: context )
                                    .map { [weak self] permanentLinkInfo throws in
                                        guard let `self` = self else { throw Abort(.internalServerError)}
                                        let  (token, artifact)  = permanentLinkInfo
                                        return try self.generatePermanentLink(token: token, artifact: artifact, platform: app.platform)
                                }
                        }
                        
                }
        }
    }
    
    //DELETE /<uuid>/link
    func deleteApplicationPermanentLink(_ req: Request) throws -> Future<MessageDto> {
        throw "not implemented"
    }
    
    
    enum InstallType:String,Decodable {
        case direct
        case page
    }
    //GET /permanentLink?token=dsf&install=direct|page
    func installPermanentLink(_ req: Request) throws -> Future<Response> {
        let reqToken = try req.query.get(String.self, at: "token")
        let installType = try req.query.get(InstallType.self, at: "install")
        let context = try req.context()
        
        return try retriveTokenInfo(tokenId: reqToken, into: context)
            .flatMap{try retrievePermanentLinkArtifact(token: $0, into: context)}
            .flatMap({ (tokenLink, artifact) in
                guard let app = tokenLink.application else { throw ApplicationError.notFound }
                guard let artifact = artifact else { throw ArtifactError.notFound }
                let config = try req.make(MdtConfiguration.self)
                
                return try self.artifactController.generateDownloadInfo(user: User.anonymous(), artifactID: artifact.uuid, platform: app.platform, applicationName: app.name, config: config, into: context)
                    .map{ dwInfo -> Response in
                        let installUrl:String
                        switch installType{
                        case .direct:
                            installUrl = dwInfo.installUrl
                        case .page:
                            installUrl = dwInfo.installPageUrl
                        }
                        return req.redirect(to: installUrl)
                }
            })
    }
    
    private func generateUrls(with token:MDTApplication.TokenLink,platform:Platform) throws -> (installUrl:String,installPageUrl:String){
        let serverUrl = externalUrl.absoluteString
        let baseInstallUrl = serverUrl + self.generateRoute(Verb.permanentLinkInstall.uri)
        
        let installUrl = baseInstallUrl + "?token=\(token.link)&install=\(InstallType.direct.rawValue)"
        let installPageUrl = baseInstallUrl + "?token=\(token.link)&install=\(InstallType.page.rawValue)"
        
        /* let installUrl = artifactController.generateDirectInstallUrl(serverExternalUrl: serverUrl, token: token.tokenId, platform: platform)
         let installPageUrl = artifactController.generateInstallPageUrl(serverExternalUrl: serverUrl, token: token.tokenId)
         */
        return (installUrl,installPageUrl)
        //throw "not implemented"
    }
    
    func applicationDetail(_ req: Request) throws -> Future<ApplicationDto> {
        let appUuid = try req.parameters.next(String.self)
        let serverUrl = externalUrl
        return try retrieveUser(from:req)
            .flatMap{user in
                guard let user = user else { throw Abort(.unauthorized)}
                let context = try req.context()
                return try findApplication(uuid: appUuid, into: context)
                    .flatMap({app in
                        guard let app = app else { throw ApplicationError.notFound }
                        //  guard let `self` = self else { throw Abort(.internalServerError)}
                        
                        let isAdminForApp = app.isAdmin(user: user)
                        //find permanent links
                        // let permanentLinks:Future<[PermanentLinkDto]?> = isAdminForApp ? req.eventLoop.future(nil) : try self.applicationPermanentLinks(req, application: app)
                        
                        return ApplicationDto.create(from: app, content:isAdminForApp ? .full : .light , in : context)
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
                .do({ [weak self] dto in self?.track(event: .DeleteApp(app: info.app, user: info.user), for: req)})
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
    func getApplicationVersionsPagined(_ req: Request,uuid:String,selectedBranch:String?,isLatestBranch:Bool = false) throws -> Future<Paginated<ArtifactDto>> {
        let context = try req.context()
        
        return try retrieveUser(from:req)
            .flatMap{ user in
                guard let _ = user else { throw Abort(.unauthorized)}
                return try App.findApplication(uuid: uuid, into: context)
        }
        .flatMap{ (app:MDTApplication?) -> Future<Paginated<ArtifactDto>>  in
            guard let app = app else { throw ApplicationError.notFound }
            let excludedBranch = isLatestBranch ? nil : lastVersionBranchName
            let (queryUse,artifactsFound) = try findArtifacts(app: app, selectedBranch: selectedBranch, excludedBranch: excludedBranch, into: context)
            return artifactsFound
                .map(transform: {ArtifactDto(from: $0)})
                .paginate(for: req, sortFields: self.artifactsSortFields,defaultSort: "created",findQuery: queryUse)
        }
    }
    
    func getApplicationVersionsGroupedAndPagined(_ req: Request,uuid:String,selectedBranch:String?,isLatestBranch:Bool = false) throws -> Future<Paginated<ArtifactGroupedDto>> {
        let context = try req.context()
        
        return try retrieveUser(from:req)
            .flatMap{ user in
                guard let _ = user else { throw Abort(.unauthorized)}
                return try App.findApplication(uuid: uuid, into: context)
        }
        .flatMap{ (app:MDTApplication?) -> Future<Paginated<ArtifactGroupedDto>>  in
            guard let app = app else { throw ApplicationError.notFound }
            let excludedBranch = isLatestBranch ? nil : lastVersionBranchName
            let (artifactsFound,countFuture) = try findAndSortArtifacts(app: app, selectedBranch: selectedBranch, excludedBranch: excludedBranch, into: context)
            return artifactsFound
                .map(transform: {ArtifactGroupedDto(from: $0)})
                .paginate(for: req, sortFields: self.groupedArtifactsSortFields,defaultSort: "created",countQuery:countFuture)
        }
    }
    
    //@ApiMethod(method: 'GET', path: 'app/{appId}/versions/grouped?branch=master')
    func getApplicationVersionsGrouped(_ req: Request) throws -> Future<Paginated<ArtifactGroupedDto>> {
        let uuid = try req.parameters.next(String.self)
        let selectedBranch = try? req.query.get(String.self, at: "branch")
        return try getApplicationVersionsGroupedAndPagined(req, uuid: uuid, selectedBranch: selectedBranch, isLatestBranch: false)
    }
    
    //@ApiMethod(method: 'GET', path: 'app/{appId}/versions?branch=master')
    func getApplicationVersions(_ req: Request) throws -> Future<Paginated<ArtifactDto>> {
        let uuid = try req.parameters.next(String.self)
        //parameters
        // let pageIndex = try? req.query.get(Int.self, at: "pageIndex")
        // let limitPerPage = try? req.query.get(Int.self, at: "limitPerPage")
        let selectedBranch = try? req.query.get(String.self, at: "branch")
        return try getApplicationVersionsPagined(req, uuid: uuid, selectedBranch: selectedBranch, isLatestBranch: false)
        // return try getApplicationVersionsWithParameters(req, uuid:uuid , pageIndex: pageIndex, limitPerPage: limitPerPage, selectedBranch: selectedBranch, isLatestBranch: false)
    }
    
    //@ApiMethod(method: 'GET', path: 'app/{appId}/versions/last')
    func getApplicationLastVersions(_ req: Request) throws -> Future<Paginated<ArtifactDto>> {
        let uuid = try req.parameters.next(String.self)
        
        return try getApplicationVersionsPagined(req, uuid: uuid, selectedBranch: lastVersionBranchName, isLatestBranch: true)
        //return try getApplicationVersionsWithParameters(req, uuid:uuid , pageIndex: nil, limitPerPage: nil, selectedBranch: lastVersionBranchName, isLatestBranch: true)
    }
    //@ApiMethod(method: 'GET', path: 'app/{appId}/versions/last/grouped')
    func getApplicationLastVersionsGrouped(_ req: Request) throws -> Future<Paginated<ArtifactGroupedDto>> {
        let uuid = try req.parameters.next(String.self)
        
        return try getApplicationVersionsGroupedAndPagined(req, uuid: uuid, selectedBranch: lastVersionBranchName, isLatestBranch: true)
        //return try getApplicationVersionsWithParameters(req, uuid:uuid , pageIndex: nil, limitPerPage: nil, selectedBranch: lastVersionBranchName, isLatestBranch: true)
    }
    
    
    //{appUUID}/maxversion/{branch}/{name}
    func maxVersion(_ req: Request) throws -> Future<MaxVersionArtifactDto> {
        let maxVersionAvailbaleDelay = 30.0 //30 Secs
        let appId = try req.parameters.next(String.self)
        let branch = try req.parameters.next(String.self)
        let name = try req.parameters.next(String.self)
        
        let ts = try req.query.get(TimeInterval.self, at: "ts")
        let tsStr = try req.query.get(String.self, at: "ts")
        let hash = try req.query.get(String.self, at: "hash")
        
        guard branch != lastVersionBranchName else {
            let error = VaporError(identifier: "invalidArgument", reason: "branch value is incorrect")
            track(event: .MaxVersion(app:nil,appUuid:appId,failedError:error), for: req)
            throw  error }
        
        let currentDelay = abs(Date().timeIntervalSince1970 - ts)
        
        if currentDelay > maxVersionAvailbaleDelay {
            let error = ApplicationError.expirationTimestamp(delay: Int(currentDelay))
            track(event: .MaxVersion(app:nil,appUuid:appId,failedError:error), for: req)
            throw error
        }
        let context = try req.context()
        return try App.findApplication(uuid: appId, into: context)
            .flatMap{ app  in
                guard let app = app, let secretKey  = app.maxVersionSecretKey else { throw ApplicationError.disabledFeature}
                //compute Hash
                let stringToHash = "ts=\(tsStr)&branch=\(branch)&hash=\(secretKey)"
                let generatedHash = stringToHash.md5()
                guard generatedHash == hash else { throw ApplicationError.invalidSignature}
                return searchMaxArtifact(app: app, branch: branch, artifactName: name, into: context)
                    .flatMap {[weak self] artifact in
                        guard let `self` = self else { throw ApplicationError.unknownPlatform }
                        guard let artifact = artifact else {throw ArtifactError.notFound }
                        let config = try req.make(MdtConfiguration.self)
                        return try self.artifactController.generateDownloadInfo(user: User.anonymous(), artifactID: artifact.uuid, platform: app.platform, applicationName: app.name, config: config, into: context)
                            .map { dwInfo in
                                return MaxVersionArtifactDto(branch: branch, name: name, version: artifact.version, info: dwInfo)
                        }
                        
                }
        }.do({[weak self]  dto in self?.track(event: .MaxVersion(app: nil, appUuid: appId, failedError: nil), for: req)})
        .catch({[weak self]  error in self?.track(event: .MaxVersion(app: nil, appUuid: appId, failedError: error), for: req)})
    }
    
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
