//
//  ApplicationsController.swift
//  App
//
//  Created by Rémi Groult on 20/02/2019.
//

import Foundation
import Vapor
//import Routing
import Swiftgger
import Meow
//import Pagination

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
    
    func createApplication(_ req: Request) throws -> EventLoopFuture<ApplicationDto> {
        let context = req.meow
        let serverUrl = externalUrl
        return try retrieveUser(from:req)
            .flatMap{user -> EventLoopFuture<ApplicationDto> in
                do {
                    guard let user = user else { throw Abort(.unauthorized)}
                    let appDto = try req.content.decode(ApplicationCreateDto.self)
                    return try App.createApplication(name: appDto.name, platform: appDto.platform, description: appDto.description, adminUser: user,base64Icon:appDto.base64IconData,maxVersionCheckEnabled:appDto.enableMaxVersionCheck, into: context)
                        .flatMap{app in
                            ApplicationDto.create(from: app, content: .full, in : context)
                                .map{$0.setIconUrl(url: app.generateIconUrl(externalUrl: serverUrl))}
                                .do({ [weak self] dto in self?.track(event: .CreateApp(app: app, user: user), for: req)})
                        }
                }
                catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            }
    }
    
    func updateApplication(_ req: Request) throws -> EventLoopFuture<ApplicationDto> {
       // let appUuid = try req.parameters.next(String.self)
        guard let appUuid = req.parameters.get("uuid") else { throw Abort(.badRequest)}
        let context = req.meow
        let serverUrl = externalUrl
        return try retrieveMandatoryUser(from:req)
            .flatMap{user -> EventLoopFuture<ApplicationDto> in
               // guard let user = user else { throw Abort(.unauthorized)}
                do {
                let applicationUpdateDto = try req.content.decode(ApplicationUpdateDto.self)
                   // .flatMap({ applicationUpdateDto in
                        return findApplication(uuid: appUuid, into: context)
                            .flatMap({ app  in
                                guard let app = app else { return req.eventLoop.makeFailedFuture(ApplicationError.notFound)}
                                //{throw ApplicationError.notFound }
                                //check if user is app admin
                                guard app.isAdmin(user: user) else { return req.eventLoop.makeFailedFuture(ApplicationError.notAnApplicationAdministrator)}
                                //{ throw ApplicationError.notAnApplicationAdministrator }
                                return App.updateApplicationWithParameters(from: app, name: applicationUpdateDto.name, description: applicationUpdateDto.description, maxVersionCheckEnabled: applicationUpdateDto.maxVersionCheckEnabled, iconData: applicationUpdateDto.base64IconData, into: context)
                                .flatMap {ApplicationDto.create(from: $0, content: .full, in : context)}
                                .map{$0.setIconUrl(url: app.generateIconUrl(externalUrl: serverUrl))}
                                .do({ [weak self] dto in self?.track(event: .UpdateApp(app: app, user: user), for: req)})
                            })
                }
                catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
        }
    }
    
    func iconApplication(_ req: Request) throws -> EventLoopFuture<ImageDto> {
        guard let appUuid = req.parameters.get("uuid") else { throw Abort(.badRequest)}
        let meow = req.meow
        return findApplication(uuid: appUuid, into: meow)
            .flatMap{ app -> EventLoopFuture<ImageDto> in
                guard let base64 = app?.base64IconData else { return req.eventLoop.makeFailedFuture(ApplicationError.iconNotFound)}
               // { throw ApplicationError.iconNotFound }
                return ImageDto.create(for: req, base64Image: base64)
                    .flatMapThrowing{ image -> ImageDto in
                        guard let image = image else {
                            //invalid icon format, erase it
                            if let app = app {
                                _ = updateApplicationWithParameters(from: app, name: nil, description: nil, maxVersionCheckEnabled: nil, iconData: "", into: meow)
                            }
                            throw ApplicationError.invalidIconFormat}
                        return image
                }
        }
    }
    
    func applications(_ req: Request) throws -> EventLoopFuture<Paginated<ApplicationSummaryDto>> {
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
            .flatMap{[weak self]user -> EventLoopFuture<Paginated<ApplicationSummaryDto>> in
                guard let `self` = self else { return req.eventLoop.makeFailedFuture(Abort(.internalServerError))}
                //{ throw Abort(.internalServerError)}
                let meow = req.meow
                let (queryUse,appFounds) =  App.findApplications(platform: platformFilter, into: meow,additionalQuery:self.extractSearch(from: req, searchField: "name"))
                return appFounds.map(transform: {self.generateSummaryDto(from:$0)})
                //return appFounds.map(transform: {ApplicationSummaryDto(from: $0).setIconUrl(url: $0.generateIconUrl(externalUrl: serverUrl))})
                    .paginate(for: req, model:MDTApplication.self, sortFields: self.sortFields,defaultSort: "created", findQuery: queryUse)
                /*return try findApplications(platform: platformFilter, into: context)
                 .map(transform: {ApplicationSummaryDto(from: $0).setIconUrl(url: $0.generateIconUrl(externalUrl: serverUrl))})
                 .getAllResults()*/
        }
    }
    
    func generateSummaryDto(from app:MDTApplication) -> ApplicationSummaryDto {
        return ApplicationSummaryDto(from: app).setIconUrl(url: app.generateIconUrl(externalUrl: externalUrl))
    }
    
    func applicationsFavorites(_ req: Request) throws -> EventLoopFuture<[ApplicationSummaryDto]> {
        let serverUrl = externalUrl
        return try retrieveMandatoryUser(from:req)
            .flatMap{user in
                // guard let `self` = self else { throw Abort(.internalServerError)}
                let meow = req.meow
                return findApplications(with: UserDto.generateFavorites(from: user.favoritesApplicationsUUID), into: meow)
                    .map(transform: {ApplicationSummaryDto(from: $0).setIconUrl(url: $0.generateIconUrl(externalUrl: serverUrl))})
                    .allResults()
        }
    }
    
    private func retrieveUserAndApp(_ req: Request, appUuid:String,needToBeAdmin:Bool) throws -> EventLoopFuture<(User,MDTApplication)> {
        let meow = req.meow
        return try retrieveMandatoryUser(from:req)
            .flatMap{user in
               // guard let user = user else { throw Abort(.unauthorized)}
                return  findApplication(uuid: appUuid, into: meow)
                    .flatMapThrowing({ app  in
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
    func applicationPermanentLinks(_ req: Request) throws -> EventLoopFuture<[PermanentLinkDto]> {
      //  let appUuid = try req.parameters.next(String.self)
        guard let appUuid = req.parameters.get("uuid") else { throw Abort(.badRequest)}
        
        return try retrieveUserAndApp(req, appUuid: appUuid, needToBeAdmin: true)
            .flatMap { (user, app) in
                let meow = req.meow
                return retrievePermanentLinks(app: app, into: meow)
                    .flatMapThrowing{ permanentLinkInfoList throws -> [PermanentLinkDto] in
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
    func createApplicationPermanentLink(_ req: Request) throws -> EventLoopFuture<PermanentLinkDto> {
        guard let appUuid = req.parameters.get("uuid") else { throw Abort(.badRequest)}
        let linkCreateDto = try req.content.decode(PermanentLinkCreateDto.self)
        
        return try retrieveUserAndApp(req, appUuid: appUuid, needToBeAdmin: true)
            .flatMap { (user, app) in
                let meow = req.meow
                let link = MDTApplication.PermanentLink(applicationUuid: appUuid, branch: linkCreateDto.branch, artifactName: linkCreateDto.artifactName, validity: linkCreateDto.daysValidity)
                do {
                    return  try App.generatePermanentLink(with: link, into: meow)
                        .flatMap{ tokenInfo in
                            let tokenLink = MDTApplication.TokenLink(tokenId: tokenInfo.uuid, application: app, link: link)
                            //throw "not implemented"
                            
                            return retrievePermanentLinkArtifact(token: tokenLink, into: meow )
                                .flatMapThrowing { [weak self] permanentLinkInfo throws in
                                    guard let `self` = self else { throw Abort(.internalServerError)}
                                    let  (token, artifact)  = permanentLinkInfo
                                    return try self.generatePermanentLink(token: token, artifact: artifact, platform: app.platform)
                                }
                        }
                }
                catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            }
    }
    
    //DELETE /<uuid>/link
    func deleteApplicationPermanentLink(_ req: Request) throws -> EventLoopFuture<MessageDto> {
        throw "not implemented"
    }
    
    
    enum InstallType:String,Decodable {
        case direct
        case page
    }
    //GET /permanentLink?token=dsf&install=direct|page
    func installPermanentLink(_ req: Request) throws -> EventLoopFuture<Response> {
        let reqToken = try req.query.get(String.self, at: "token")
        let installType = try req.query.get(InstallType.self, at: "install")
        let meow = req.meow
        
        return try retriveTokenInfo(tokenId: reqToken, into: meow)
            .flatMap{retrievePermanentLinkArtifact(token: $0, into: meow)}
            .flatMap({ (tokenLink, artifact) in
                do {
                guard let app = tokenLink.application else { throw ApplicationError.notFound }
                guard let artifact = artifact else { throw ArtifactError.notFound }
                let config = try req.application.appConfiguration() //try req.make(MdtConfiguration.self)
                
                return self.artifactController.generateDownloadInfo(user: User.anonymous(), artifactID: artifact.uuid, application: app, config: config, into: meow)
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
            }
            catch {
                return req.eventLoop.makeFailedFuture(error)
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
    
    func applicationDetail(_ req: Request) throws -> EventLoopFuture<ApplicationDto> {
       // let appUuid = try req.parameters.next(String.self)
        guard let appUuid = req.parameters.get("uuid") else { throw Abort(.badRequest)}
        let serverUrl = externalUrl
        return try retrieveMandatoryUser(from:req)
            .flatMap{user in
              //  guard let user = user else { throw Abort(.unauthorized)}
                let meow = req.meow
                return findApplication(uuid: appUuid, into: meow)
                    .flatMap({app in
                        guard let app = app else { return req.eventLoop.makeFailedFuture(ApplicationError.notFound)}
                        //{ throw ApplicationError.notFound }
                        //  guard let `self` = self else { throw Abort(.internalServerError)}
                        
                        let isAdminForApp = app.isAdmin(user: user)
                        //find permanent links
                        // let permanentLinks:Future<[PermanentLinkDto]?> = isAdminForApp ? req.eventLoop.future(nil) : try self.applicationPermanentLinks(req, application: app)
                        
                        return ApplicationDto.create(from: app, content:isAdminForApp ? .full : .light , in : meow)
                            .map{$0.setIconUrl(url: app.generateIconUrl(externalUrl: serverUrl))}
                        
                    })}
    }
    
    // @ApiMethod(method: 'DELETE', path: 'app/{appId}')
    func deleteApplication(_ req: Request) throws -> EventLoopFuture<MessageDto> {
        let storage = try req.storageService()
        return try findApplicationInfo(from:req, needAdmin: true)
            .flatMap({ info  in
                let meow = req.meow
                //  try req.make(StorageServiceProtocol.self)
                return App.deleteAllArtifacts(app: info.app, storage: storage, into: meow)
                    .flatMap{
                        return App.deleteApplication(by: info.app, into: meow).map {
                            return MessageDto(message: "Application Deleted")
                        }
                }
                .do({ [weak self] dto in self?.track(event: .DeleteApp(app: info.app, user: info.user), for: req)})
            })
    }
    
    //@ApiMethod(method: 'PUT', path: 'app/{appId}/adminUsers/{email}')
    func addAdminUser(_ req: Request) throws -> EventLoopFuture<MessageDto> {
        guard let email = req.parameters.get("email") else { throw Abort(.badRequest)}
        return try findApplicationInfo(from:req, needAdmin: true)
            .flatMap({ info  in
                //  let email = try req.parameters.next(String.self)
                let meow = req.meow
                //find user with email
                return findUser(by: email, into: meow)
                    .flatMap({user in
                        do {
                            guard let user = user else { throw ApplicationError.invalidApplicationAdministrator }
                            return try info.app.addAdmin(user: user, into: meow)
                                .map{ _ in MessageDto(message: "Admin User Added") }
                        }
                        catch {
                            return req.eventLoop.makeFailedFuture(error)
                        }
                    })
            })
    }
    
    //@ApiMethod(method: 'DELETE', path: 'app/{appId}/adminUsers/{email}')
    func deleteAdminUser(_ req: Request) throws -> EventLoopFuture<MessageDto> {
        guard let email = req.parameters.get("email") else { throw Abort(.badRequest)}
        return try findApplicationInfo(from:req, needAdmin: true)
            .flatMap({ info  in
                //let email = try req.parameters.next(String.self)
                let meow = req.meow
                //find user with email
                return  findUser(by: email, into: meow)
                    .flatMap({user in
                        do {
                            guard let user = user else { throw ApplicationError.invalidApplicationAdministrator }
                            guard info.app.adminUsers.count > 1 else { throw ApplicationError.deleteLastApplicationAdministrator }
                            return try info.app.removeAdmin(user: user, into: meow)
                                .map{ _ in MessageDto(message: "Admin User Added") }
                        }
                        catch {
                            return req.eventLoop.makeFailedFuture(error)
                        }
                    })
            })
    }
    func getApplicationVersionsPagined(_ req: Request,uuid:String,selectedBranch:String?,isLatestBranch:Bool = false) throws -> EventLoopFuture<Paginated<ArtifactDto>> {
        let meow = req.meow
        
        return try retrieveMandatoryUser(from:req)
            .flatMap{ user in
                return App.findApplication(uuid: uuid, into: meow)
        }
        .flatMap{ (app:MDTApplication?) -> EventLoopFuture<Paginated<ArtifactDto>>  in
            do {
            guard let app = app else { throw ApplicationError.notFound }
            let excludedBranch = isLatestBranch ? nil : lastVersionBranchName
            let (queryUse,artifactsFound) = try findArtifacts(app: app, selectedBranch: selectedBranch, excludedBranch: excludedBranch, into: meow)
            return artifactsFound
                .map(transform: {ArtifactDto(from: $0)})
                .paginate(for: req, model: Artifact.self, sortFields: self.artifactsSortFields,defaultSort: "created",findQuery: queryUse)
        }
        catch {
            return req.eventLoop.makeFailedFuture(error)
        }
        }
    }
    
    func getApplicationVersionsGroupedAndPagined(_ req: Request,uuid:String,selectedBranch:String?,isLatestBranch:Bool = false) throws -> EventLoopFuture<Paginated<ArtifactGroupedDto>> {
        let meow = req.meow
        
        return try retrieveMandatoryUser(from:req)
            .flatMap{ user in
                return App.findApplication(uuid: uuid, into: meow)
        }
        .flatMap{ (app:MDTApplication?) -> EventLoopFuture<Paginated<ArtifactGroupedDto>>  in
            do {
            guard let app = app else { throw ApplicationError.notFound }
            let excludedBranch = isLatestBranch ? nil : lastVersionBranchName
            let (artifactsFound,countFuture) = try findAndSortArtifacts(app: app, selectedBranch: selectedBranch, excludedBranch: excludedBranch, into: meow)
            return artifactsFound
                .map(transform: {ArtifactGroupedDto(from: $0)})
                .paginate(for: req, model: MDTApplication.self, sortFields: self.groupedArtifactsSortFields,defaultSort: "created",countQuery:countFuture)
        }
        catch {
            return req.eventLoop.makeFailedFuture(error)
        }
        }
    }
    
    //@ApiMethod(method: 'GET', path: 'app/{appId}/versions/grouped?branch=master')
    func getApplicationVersionsGrouped(_ req: Request) throws -> EventLoopFuture<Paginated<ArtifactGroupedDto>> {
        guard let uuid = req.parameters.get("uuid") else { throw Abort(.badRequest)}
        let selectedBranch = try? req.query.get(String.self, at: "branch")
        return try getApplicationVersionsGroupedAndPagined(req, uuid: uuid, selectedBranch: selectedBranch, isLatestBranch: false)
    }
    
    //@ApiMethod(method: 'GET', path: 'app/{appId}/versions?branch=master')
    func getApplicationVersions(_ req: Request) throws -> EventLoopFuture<Paginated<ArtifactDto>> {
        guard let uuid = req.parameters.get("uuid") else { throw Abort(.badRequest)}
        //parameters
        // let pageIndex = try? req.query.get(Int.self, at: "pageIndex")
        // let limitPerPage = try? req.query.get(Int.self, at: "limitPerPage")
        let selectedBranch = try? req.query.get(String.self, at: "branch")
        return try getApplicationVersionsPagined(req, uuid: uuid, selectedBranch: selectedBranch, isLatestBranch: false)
        // return try getApplicationVersionsWithParameters(req, uuid:uuid , pageIndex: pageIndex, limitPerPage: limitPerPage, selectedBranch: selectedBranch, isLatestBranch: false)
    }
    
    //@ApiMethod(method: 'GET', path: 'app/{appId}/versions/last')
    func getApplicationLastVersions(_ req: Request) throws -> EventLoopFuture<Paginated<ArtifactDto>> {
        guard let uuid = req.parameters.get("uuid") else { throw Abort(.badRequest)}
        
        return try getApplicationVersionsPagined(req, uuid: uuid, selectedBranch: lastVersionBranchName, isLatestBranch: true)
        //return try getApplicationVersionsWithParameters(req, uuid:uuid , pageIndex: nil, limitPerPage: nil, selectedBranch: lastVersionBranchName, isLatestBranch: true)
    }
    //@ApiMethod(method: 'GET', path: 'app/{appId}/versions/last/grouped')
    func getApplicationLastVersionsGrouped(_ req: Request) throws -> EventLoopFuture<Paginated<ArtifactGroupedDto>> {
        guard let uuid = req.parameters.get("uuid") else { throw Abort(.badRequest)}
        
        return try getApplicationVersionsGroupedAndPagined(req, uuid: uuid, selectedBranch: lastVersionBranchName, isLatestBranch: true)
        //return try getApplicationVersionsWithParameters(req, uuid:uuid , pageIndex: nil, limitPerPage: nil, selectedBranch: lastVersionBranchName, isLatestBranch: true)
    }
    
    
    //{appUUID}/maxversion/{branch}/{name}
    func maxVersion(_ req: Request) throws -> EventLoopFuture<MaxVersionArtifactDto> {
        let maxVersionAvailbaleDelay = 30.0 //30 Secs
        guard let appId = req.parameters.get("uuid") else { throw Abort(.badRequest)}
        guard let branch = req.parameters.get("branch") else { throw Abort(.badRequest)}
        guard let name = req.parameters.get("name") else { throw Abort(.badRequest)}
        
        let ts = try req.query.get(TimeInterval.self, at: "ts")
        let tsStr = try req.query.get(String.self, at: "ts")
        let hash = try req.query.get(String.self, at: "hash")

        let trackingContext = ActivityContext()
        
        guard branch != lastVersionBranchName else {
            let error = Abort(.badRequest, reason: "branch value is incorrect", identifier: "invalidArgument")
            track(event: .MaxVersion(context:trackingContext,appUuid:appId,failedError:error), for: req)
            throw  error }
        
        let currentDelay = abs(Date().timeIntervalSince1970 - ts)
        
        if currentDelay > maxVersionAvailbaleDelay {
            let error = ApplicationError.expirationTimestamp(delay: Int(currentDelay))
            track(event: .MaxVersion(context:trackingContext,appUuid:appId,failedError:error), for: req)
            throw error
        }
        let meow = req.meow
        return App.findApplication(uuid: appId, into: meow)
            .flatMap{ app  in
                guard let app = app, let secretKey  = app.maxVersionSecretKey else { return req.eventLoop.makeFailedFuture(ApplicationError.disabledFeature)}
                //{ throw ApplicationError.disabledFeature}
                trackingContext.application = app
                //compute Hash
                let stringToHash = "ts=\(tsStr)&branch=\(branch)&hash=\(secretKey)"
                let generatedHash = stringToHash.md5()
                guard generatedHash == hash else { return req.eventLoop.makeFailedFuture(ApplicationError.invalidSignature)}
                //{ throw ApplicationError.invalidSignature}
                return searchMaxArtifact(app: app, branch: branch, artifactName: name, into: meow)
                    .flatMap {[weak self] artifact in
                        do {
                        guard let `self` = self else { throw ApplicationError.unknownPlatform }
                        guard let artifact = artifact else {throw ArtifactError.notFound }
                            let config = try req.application.appConfiguration() // try req.make(MdtConfiguration.self)
                        return self.artifactController.generateDownloadInfo(user: User.anonymous(), artifactID: artifact._id.hexString, application: app, config: config, into: meow)
                            .map { dwInfo in
                                return MaxVersionArtifactDto(branch: branch, name: name, version: artifact.version, info: dwInfo)
                        }
                    }
                    catch {
                        return req.eventLoop.makeFailedFuture(error)
                    }
                        
                }
        }.do({[weak self]  dto in self?.track(event: .MaxVersion(context:trackingContext, appUuid: appId, failedError: nil), for: req)})
        .catch({[weak self]  error in self?.track(event: .MaxVersion(context:trackingContext, appUuid: appId, failedError: error), for: req)})
    }
    
    private func findApplicationInfo(from req: Request, needAdmin:Bool) throws -> EventLoopFuture<(user:User,app:MDTApplication)>{
        guard let uuid = req.parameters.get("uuid") else { throw Abort(.badRequest)}
        return try retrieveMandatoryUser(from:req)
            .flatMap({ user in
                let meow = req.meow
                return App.findApplication(uuid: uuid, into: meow)
                    .flatMapThrowing({ app in
                        guard let app = app else { throw ApplicationError.notFound }
                        if needAdmin {
                            guard app.isAdmin(user: user)  else { throw ApplicationError.notAnApplicationAdministrator}
                        }
                        return (user,app)
                    })
            })
    }
}
