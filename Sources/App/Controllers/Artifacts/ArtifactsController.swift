//
//  ArtifactsController.swift
//  App
//
//  Created by Rémi Groult on 18/02/2019.
//

import Vapor
import Vapor
import Swiftgger
import Meow

let IPA_CONTENT_TYPE = "application/octet-stream ipa"
let BINARY_CONTENT_TYPE = "application/octet-stream"
let APK_CONTENT_TYPE = "application/vnd.android.package-archive"

enum customHeadersName:String {
    case filename = "x-filename"
    case sortIdentifier = "x-sortidentifier"
    case metaTags = "x-metatags"
    case mimeType = "x-mimetype"
}

final class ArtifactsController:BaseController  {
    
    let maxUploadSize = 1024*1024*1024*1024
    
    init(apiBuilder:OpenAPIBuilder?) {
        super.init(version: "v2", pathPrefix: "Artifacts", apiBuilder: apiBuilder)
    }
    
    private func createArtifactWithInfo(_ req: Request,apiKey:String,branch:String,version:String,artifactName:String) throws -> Future<ArtifactDto> {
        let headerFilename = req.http.headers.firstValue(name: HTTPHeaderName(customHeadersName.filename.rawValue))
        var sortIdentifier = req.http.headers.firstValue(name: HTTPHeaderName(customHeadersName.sortIdentifier.rawValue))
        let metaTagsHeader = req.http.headers.firstValue(name: HTTPHeaderName(customHeadersName.metaTags.rawValue))
        guard req.http.headers.firstValue(name: .contentType) == BINARY_CONTENT_TYPE else { throw Abort(.unsupportedMediaType)}
        let mimeType = req.http.headers[customHeadersName.mimeType.rawValue].last
        let metaTags:[String : String]?
        if let metaTagsHeader = metaTagsHeader {
            metaTags = try? JSONDecoder().decode([String : String].self,from: metaTagsHeader.convertToData())
        }else {
            metaTags = nil
        }
        if sortIdentifier?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            sortIdentifier = nil
        }
        let filename:String
        if let lastPath = headerFilename?.split(separator:"/").last {
            filename = String(lastPath)
        }else {
            filename = "artifact"
        }
        let context = try req.context()
        let trackingContext = ActivityContext()

        return try findApplication(apiKey: apiKey, into: context)
            .flatMap({ app -> Future<Artifact>  in
                guard let app = app else { throw ApplicationError.notFound }
                trackingContext.application = app
                //test contentType
                switch app.platform {
                case .android:
                    guard mimeType == APK_CONTENT_TYPE else { throw ArtifactError.invalidContentType}
                case .ios:
                    guard mimeType == IPA_CONTENT_TYPE else { throw ArtifactError.invalidContentType}
                }
                
                //already Exist
                return try isArtifactAlreadyExist(app: app, branch: branch, version: version, name: artifactName, into: context)
                    .flatMap({ isExist  in
                        guard isExist == false else { throw ArtifactError.alreadyExist}
                        return req.http.body.consumeData(max: self.maxUploadSize, on: req.eventLoop)
                            .flatMap({ data -> Future<Artifact> in
                                let artifact = try createArtifact(app: app, name: artifactName, version: version, branch: branch, sortIdentifier: sortIdentifier, tags: metaTags)
                                let storage = try req.make(StorageServiceProtocol.self)
                                return try storeArtifactData(data: data, filename: filename, contentType: mimeType, artifact: artifact, storage: storage, into: context)
                            })
                    })
                    .do({[weak self]  artifact in self?.track(event: .UploadArtifact(context:trackingContext, artifact: artifact), for: req)})
                    .catch({[weak self]  error in self?.track(event: .UploadArtifact(context:trackingContext, artifact: nil, failedError: error), for: req)})
            })
            .flatMap{try saveArtifact(artifact: $0, into: context)}
            .map{ArtifactDto(from: $0)}
    }
    
    //POST '{apiKey}/{branch}/{version}/{artifactName}
    func createArtifactByApiKey(_ req: Request) throws -> Future<ArtifactDto> {
        let apiKey = try req.parameters.next(String.self)
        let branch = try req.parameters.next(String.self)
        let version = try req.parameters.next(String.self)
        let artifactName = try req.parameters.next(String.self)
        
        return try createArtifactWithInfo(req, apiKey: apiKey, branch: branch, version: version, artifactName: artifactName)
    }
    
    private func deleteArtifactWithInfo(_ req: Request,apiKey:String,branch:String,version:String,artifactName:String) throws -> Future<MessageDto> {
        let context = try req.context()

        let trackingContext = ActivityContext()

        return try findApplication(apiKey: apiKey, into: context)
            .flatMap({ app throws -> Future<Artifact?> in
                guard let app = app else { throw ApplicationError.notFound }
                trackingContext.application = app
                return try findArtifact(app: app, branch: branch, version: version, name: artifactName, into: context)})
                   // .map{(app, $0)}})
            .flatMap({ artifact  throws -> Future<Artifact> in
                guard let artifact = artifact else { throw ArtifactError.notFound }
                let storage = try req.make(StorageServiceProtocol.self)
                return App.deleteArtifact(by: artifact, storage: storage, into: context).map{artifact}})
            .do({[weak self]  artifact in self?.track(event: .DeleteArtifact(context:trackingContext, artifact: artifact), for: req)})
            .catch({[weak self]  error in self?.track(event: .DeleteArtifact(context:trackingContext, artifact: nil, failedError: error), for: req)})
            .map {_ in return  MessageDto(message: "Artifact Deleted")}
    }
    
    //DELETE '{apiKey}/{branch}/{version}/{artifactName}
    func deleteArtifactByApiKey(_ req: Request) throws -> Future<MessageDto> {
        let apiKey = try req.parameters.next(String.self)
        let branch = try req.parameters.next(String.self)
        let version = try req.parameters.next(String.self)
        let artifactName = try req.parameters.next(String.self)
        
        return try deleteArtifactWithInfo(req, apiKey: apiKey, branch: branch, version: version, artifactName: artifactName)
    }
    
    //POST  '{apiKey}/last/{_artifactName}
    func createLastArtifactByApiKey(_ req: Request) throws -> Future<ArtifactDto> {
        let apiKey = try req.parameters.next(String.self)
        let artifactName = try req.parameters.next(String.self)
        let branch = lastVersionBranchName
        let version = lastVersionName
        
        return try createArtifactWithInfo(req, apiKey: apiKey, branch: branch, version: version, artifactName: artifactName)
    }
    
    //DELETE  '{apiKey}/last/{_artifactName}
    func deleteLastArtifactByApiKey(_ req: Request) throws -> Future<MessageDto> {
        let apiKey = try req.parameters.next(String.self)
        let artifactName = try req.parameters.next(String.self)
        let branch = lastVersionBranchName
        let version = lastVersionName
        
        return try deleteArtifactWithInfo(req, apiKey: apiKey, branch: branch, version: version, artifactName: artifactName)
    }
    
    //GET 'artifacts/{idArtifact}/download'
    func downloadInfo(_ req: Request) throws -> Future<DownloadInfoDto> {
        let config = try req.make(MdtConfiguration.self)
        let artifactId = try req.parameters.next(String.self)
        let context = try req.context()
        let trackingContext = ActivityContext()
        return try retrieveUser(from:req)
            .flatMap{user in
                guard let user = user else { throw Abort(.unauthorized)}
                trackingContext.user = user
                return try findArtifact(byUUID: artifactId, into: context)
                    .flatMap({[unowned self] artifact in
                        guard let artifact = artifact else { throw ArtifactError.notFound }
                        return artifact.application.resolve(in: context)
                            .flatMap{application in
                                trackingContext.application = application
                                return try self.generateDownloadInfo(user: user, artifactID: artifact._id.hexString, application:application, config: config, into: context)
                        }
                        .do({[weak self] dto in self?.track(event: .DownloadArtifact(context:trackingContext, artifact:artifact), for: req)})
                    })
        }
    }
    
    enum ArtifactTokenKeys:String {
        case user, appName, artifactId, baseDownloadUrl, baseIconUrl
    }
    func generateDownloadInfo(user:User,artifactID:String,application:MDTApplication, config:MdtConfiguration,into context:Context) throws -> Future<DownloadInfoDto>{
        // let config = try req.make(MdtConfiguration.self)
        let validity = 3 // 3 mins
        let baseArtifactPath = config.serverUrl.absoluteString
        
        let durationInSecs = validity * 60
        //base download URL
        let baseDownloadUrl = baseArtifactPath + self.generateRoute(Verb.artifactFile.path)
        let iconUrl = baseArtifactPath + self.generateRoute(Verb.icon.path)
        //create token with Info
        let tokenInfo = [ArtifactTokenKeys.user.rawValue:user.email,
                         ArtifactTokenKeys.appName.rawValue:application.name,
                         ArtifactTokenKeys.artifactId.rawValue:artifactID,
                         ArtifactTokenKeys.baseDownloadUrl.rawValue: baseDownloadUrl,
                         ArtifactTokenKeys.baseIconUrl.rawValue: iconUrl]
        return store(info: tokenInfo, durationInSecs: TimeInterval(durationInSecs) , into: context)
            .map{[unowned self] token  in
                let downloadUrl = baseDownloadUrl + "?token=\(token)"
                let installUrl = self.generateDirectInstallUrl(serverExternalUrl: baseArtifactPath, token: token, platform: application.platform)
                /*  if platform == .ios {
                    let plistInstallUrl = baseArtifactPath + self.generateRoute(Verb.artifactiOSManifest.path) + "?token=\(token)"
                    installUrl = self.generateItmsUrl(plistUrl:plistInstallUrl)
                }else {
                    installUrl = downloadUrl
                }*/
                let installPageUrl = self.generateInstallPageUrl(serverExternalUrl: baseArtifactPath, token: token)
                return DownloadInfoDto(directLinkUrl: downloadUrl, installUrl: installUrl, installPageUrl: installPageUrl, validity: validity)
        }
    }
    
    
    func generateInstallPageUrl(serverExternalUrl:String,token:String)->String {
        let baseArtifactPath = serverExternalUrl
        return baseArtifactPath + self.generateRoute(Verb.installPage.path) + "?token=\(token)"
    }
    
    func generateDirectInstallUrl(serverExternalUrl:String,token:String,platform:Platform)->String {
        let baseArtifactPath = serverExternalUrl
        let installUrl:String
        if platform == .ios {
            let plistInstallUrl = baseArtifactPath + self.generateRoute(Verb.artifactiOSManifest.path) + "?token=\(token)"
            installUrl = self.generateItmsUrl(plistUrl:plistInstallUrl)
        }else {
            let baseDownloadUrl = baseArtifactPath + self.generateRoute(Verb.artifactFile.path)
            let downloadUrl = baseDownloadUrl + "?token=\(token)"
            installUrl = downloadUrl
        }
        
        return installUrl
    }
    
    private func generateItmsUrl(plistUrl:String) -> String {
        //"itms-services://?action=download-manifest&url="
        var urlComponents = URLComponents()
        urlComponents.scheme = "itms-services"
        urlComponents.host = ""
        urlComponents.path = ""
        let queryItems = [URLQueryItem(name: "action", value: "download-manifest"),URLQueryItem(name: "url", value: plistUrl)]
        urlComponents.queryItems = queryItems
        
        return urlComponents.url?.absoluteString ?? plistUrl
    }
    
    //GET /icon?token='
    func downloadArtifactIcon(_ req: Request) throws -> Future<ImageDto> {
        let reqToken = try? req.query.get(String.self, at: "token")
        guard let token = reqToken else { throw  Abort(.badRequest, reason: "Token not found") }
        let context = try req.context()
        
        return findInfo(with: token, into: context)
            .flatMap{ info -> Future<Artifact?> in
                guard let info = info, let id = info[ArtifactTokenKeys.artifactId.rawValue] else { throw  Abort(.badRequest, reason: "Token not found or expired") }
                return try findArtifact(byID: id, into: context)
        }
        .flatMap{ artifact -> Future<MDTApplication> in
            guard let artifact = artifact else { throw  Abort(.serviceUnavailable, reason: "Token content Invalid") }
            return artifact.application.resolve(in: context)
        }
        .flatMap{ app ->  Future<ImageDto> in
            return ImageDto.create(within: req.eventLoop, base64Image: app.base64IconData, alternateBase64: defaultDownloadIcon)
                .map{ imgDto in
                    guard let imageDto = imgDto else { throw  Abort(.notFound, reason: "Icon not found") }
                    return imageDto
            }
        }
    }
    
    //GET /ios_plist?token='
    func downloadArtifactManifest(_ req: Request) throws -> Future<Response> {
        let reqToken = try? req.query.get(String.self, at: "token")
        guard let token = reqToken else { throw  Abort(.badRequest, reason: "Token not found") }
        let context = try req.context()
        return findInfo(with: token, into: context)
            .flatMap{ info in
                guard let info = info, let id = info[ArtifactTokenKeys.artifactId.rawValue], let baseDwUrl = info[ArtifactTokenKeys.baseDownloadUrl.rawValue] , let name = info[ArtifactTokenKeys.appName.rawValue], let baseIconUrl =  info[ArtifactTokenKeys.baseIconUrl.rawValue] else { throw  Abort(.badRequest, reason: "Token not found or expired") }
                return try findArtifact(byID: id, into: context)
                    .map {artifact -> Response in
                        guard let artifact = artifact else { throw  Abort(.serviceUnavailable, reason: "Artifact not found for ID") }
                        //file download
                        let downloadUrl = baseDwUrl + "?token=\(token)"
                        let iconUrl = baseIconUrl + "?token=\(token)"
                        let metaData = artifact.retrieveMetaData()
                        guard let bundleID = metaData?["CFBundleIdentifier"], let bundleVersion = metaData?["CFBundleVersion"] else { throw  Abort(.serviceUnavailable, reason: "Artifact infos not found for ID") }
                        let manifest = ArtifactsController.generateiOsManifest(absoluteIpaUrl: downloadUrl, bundleIdentifier: bundleID, bundleVersion: bundleVersion, ApplicationName: name, ApplicationIconUrl: iconUrl)
                        return req.response(manifest, as: .xml)
                        
                }
        }
    }
    
    //GET /install?token='
    func installArtifactPage(_ req: Request) throws -> Future<Response> {
        let reqToken = try? req.query.get(String.self, at: "token")
        guard let token = reqToken else { throw  Abort(.badRequest, reason: "Token not found") }
        let context = try req.context()
        let config = try req.make(MdtConfiguration.self)
        
        return findInfo(with: token, into: context)
            .flatMap{ info -> Future<Artifact?> in
                guard let info = info, let id = info[ArtifactTokenKeys.artifactId.rawValue] else { throw  Abort(.badRequest, reason: "Token not found or expired") }
                return try findArtifact(byID: id, into: context)
        }
        .flatMap{ artifact in
            guard let artifact = artifact else { throw  Abort(.serviceUnavailable, reason: "Token content Invalid") }
            return artifact.application.resolve(in: context)
                .map({ app in
                    let installUrl = self.generateDirectInstallUrl(serverExternalUrl: config.serverUrl.absoluteString, token: token, platform: app.platform)
                    return req.response(generateInstallPage(for: artifact, into: app,installUrl: installUrl), as:.html)
                })
        }
    }
    
    //GET /file?token='
    func downloadArtifactFile(_ req: Request) throws -> Future<Response> {
        let reqToken = try? req.query.get(String.self, at: "token")
        guard let token = reqToken else { throw  Abort(.badRequest, reason: "Token not found") }
        let context = try req.context()
        let storage = try req.make(StorageServiceProtocol.self)
        
        return findInfo(with: token, into: context)
            .flatMap{ info -> Future<Artifact?> in
                guard let info = info, let id = info[ArtifactTokenKeys.artifactId.rawValue] else { throw  Abort(.badRequest, reason: "Token not found or expired") }
                return try findArtifact(byID: id, into: context)
                // throw "not implemented"
        }
        .flatMap{ artifact in
            guard let artifact = artifact else { throw  Abort(.serviceUnavailable, reason: "Artifact not found for ID") }
            return try retrieveArtifactData(artifact: artifact, storage: storage, into: context)
                //return req.response("not implemented", as: .xml)
                .flatMap{ storeResult  in
                    /*  guard let mediaType = MediaType.parse(artifact.contentType ?? "") else { throw  Abort(.internalServerError, reason: "invalid Artifact mime Type") }
                     response.http.contentType = mediaType*/
                    let response:Response
                    switch storeResult {
                    case .asFile(let file):
                        ()
                        response = req.response("not implemented", as: .xml)
                    //TO DO
                    case .asUrI(let url):
                        if url.scheme == "file"{ //local files
//                            return try req.fileio().read(file: url.path).map{ data in
//                                let response = req.response()
//
//                                response.http =  HTTPResponse()
//                                response.http.body = data.convertToHTTPBody()
//                                let contentType = MediaType.parse(artifact.contentType?.data(using: .utf8) ?? Data()) ?? MediaType.binary
//                                response.http.contentType = contentType
//                                response.http.headers.add(name: "Content-Disposition", value: "attachment; filename=\(artifact.filename ?? "file")")
//                                return response
//                            }

                           return try req.streamFile(at: url.path)
                                .map { response in
                                    let contentType = MediaType.parse(artifact.contentType?.data(using: .utf8) ?? Data()) ?? MediaType.binary
                                    response.http.contentType = contentType
                                    // remove transfer encoding header and replace to "real" content length
                                    // to be able to have progresss download OTA
                                    response.http.headers.remove(name: .transferEncoding)
                                    response.http.headers.replaceOrAdd(name: "Content-Disposition", value: "attachment; filename=\(artifact.filename ?? "file")")
                                    if let contentSize =  artifact.size {
                                         response.http.headers.replaceOrAdd(name: .contentLength, value: "\(contentSize)")
                                    }
                                    return response
                            }
                        }else {
                            //redirect to it
                            response = req.redirect(to: url.absoluteString)
                        }
                    }
                    return req.eventLoop.newSucceededFuture(result: response)
                    //let response = req.response()
                    
                    //response.http.body =
                    //   return req.response("not implemented", as: .xml)
                    //throw "not implemented"
            }
        }
        
    }
    
    func deploy(_ req: Request) throws -> Future<Response> {
        let apiKey = try req.parameters.next(String.self)
        let context = try req.context()
        let config = try req.make(MdtConfiguration.self)
        return try findApplication(apiKey: apiKey, into: context).map{app in
            guard let _ = app else { throw ApplicationError.notFound }
            let baseUrl = config.serverUrl.appendingPathComponent(config.pathPrefix)
            let scriptCode = pythonDeployScript(apiKey: apiKey, exernalServerHost: baseUrl.absoluteString)
            return req.response(scriptCode,as: MediaType(type: "application", subType: "x-python-code"))
        }
    }
}
