//
//  ApplicationService.swift
//  App
//
//  Created by Rémi Groult on 25/02/2019.
//

import Vapor
import Meow

let lastVersionBranchName = "@@@@LAST####"
let lastVersionName = "latest"

enum ApplicationError: Error,Equatable {
    case notFound
    case alreadyExist
    case notAnApplicationAdministrator
    case invalidApplicationAdministrator
    case deleteLastApplicationAdministrator
    case iconNotFound
    case invalidIconFormat
    case expirationTimestamp(delay:Int)
    case disabledFeature
    case invalidSignature
    case unknownPlatform
    case expiredLink
}

extension ApplicationError:DebuggableError {
    var reason: String {
        switch self {
        case .alreadyExist:
            return "ApplicationError.alreadyExist"
        case .notAnApplicationAdministrator:
            return "ApplicationError.notAnApplicationAdministrator"
        case .invalidApplicationAdministrator:
            return "ApplicationError.invalidApplicationAdministrator"
        case .notFound:
            return "ApplicationError.notFound"
        case .deleteLastApplicationAdministrator:
            return "ApplicationError.deleteLastApplicationAdministrator"
        case .unknownPlatform:
            return "ApplicationError.unknownPlatform"
        case .iconNotFound:
            return "ApplicationError.iconNotFound"
        case .invalidIconFormat:
            return "ApplicationError.invalidIconFormat"
        case .expirationTimestamp:
            return "ApplicationError.expirationTimestamp"
        case .disabledFeature:
            return "ApplicationError.disabledFeature"
        case .invalidSignature:
            return "ApplicationError.invalidSignature"
        case .expiredLink:
            return "ApplicationError.expiredLink"
        }
    }
    
    var identifier: String {
        return "ApplicationError"
    }
}

func findApplications(platform:Platform? = nil ,into context:Meow.MeowDatabase,additionalQuery:MongoKittenQuery?) throws -> (MongoKittenQuery,MappedCursor<FindQueryBuilder, MDTApplication>){
    let query:MongoKittenQuery
    let anotherQuery = additionalQuery ?? AndQuery(conditions: [])
    if let platorm = platform {
        query =  anotherQuery && "platform" == platorm.rawValue //    Query.and([anotherQuery,Query.valEquals(field: "platform", val: platorm.rawValue)])
    }else {
        query = anotherQuery
    }
    let collection = context.collection(for: MDTApplication.self).find(where:query)
    return (query,context.collection(for: MDTApplication.self).find(where:query)) //   .find(MDTApplication.self,where:query))
}

func findApplications(with uuids:[String], into context:Meow.MeowDatabase) throws  -> MappedCursor<FindQueryBuilder, MDTApplication>{
    //ex : db.getCollection('feed').find({"_id" : {"$in" : [ObjectId("55880c251df42d0466919268"), ObjectId("55bf528e69b70ae79be35006")]}});
    let query: Document = ["uuid" : ["$in": uuids]]
    return context.collection(for: MDTApplication.self).find(where: query)
}


func findApplications(for user:User, into context:Meow.MeowDatabase) throws  -> MappedCursor<FindQueryBuilder, MDTApplication>{
    let query: Document = ["$eq": user._id]
    return context.find(MDTApplication.self, where: Query.containsElement(field: "adminUsers", match: Query.custom(query)))
}

func findApplication(name:String,platform:Platform,into context:Meow.MeowDatabase) throws -> EventLoopFuture<MDTApplication?> {
    return context.findOne(MDTApplication.self, where: Query.and([Query.valEquals(field: "name", val: name),Query.valEquals(field: "platform", val: platform.rawValue)]))
}

func findApplication(apiKey:String,into context:Meow.MeowDatabase) throws -> EventLoopFuture<MDTApplication?> {
    return context.findOne(MDTApplication.self, where:Query.valEquals(field: "apiKey", val: apiKey))
}

func findApplication(uuid:String,into context:Meow.MeowDatabase) throws -> EventLoopFuture<MDTApplication?> {
    return context.findOne(MDTApplication.self, where: Query.valEquals(field: "uuid", val: uuid))
}

func createApplication(name:String,platform:Platform,description:String,adminUser:User, base64Icon:String? = nil,maxVersionCheckEnabled:Bool? = nil, into context:Meow.Context) throws -> EventLoopFuture<MDTApplication> {
    return try findApplication(name: name, platform: platform, into: context)
        .flatMap({ app  in
            guard app == nil else { throw ApplicationError.alreadyExist }
            let createdApplication = MDTApplication(name: name, platform: platform, adminUser: adminUser, description: description)
            return try updateApplicationWithParameters(from: createdApplication, name: name, description: description, maxVersionCheckEnabled: maxVersionCheckEnabled, iconData: base64Icon, into: context)
            /*
            return ImageDto.create(within: context.eventLoop, base64Image: base64Icon)
                .flatMap({icon in
                    //base64Icon AND icon ?
                    if let _ = base64Icon {
                        guard let _ = icon  else { throw ApplicationError.invalidIconFormat }
                    }
                    let createdApplication = MDTApplication(name: name, platform: platform, adminUser: adminUser, description: description, base64Icon: base64Icon,maxVersionCheckEnabled:maxVersionCheckEnabled)
                    return  createdApplication.save(to: context).map{ createdApplication}
                })*/
            /*
            if let iconData = base64Icon {
                guard let _ = ImageDto(from: iconData) else { throw ApplicationError.invalidIconFormat }
            }
            let createdApplication = MDTApplication(name: name, platform: platform, adminUser: adminUser, description: description, base64Icon: base64Icon)
            return  createdApplication.save(to: context).map{ createdApplication}*/
        })
}

func updateApplicationWithParameters(from app:MDTApplication, name:String?, description:String?, maxVersionCheckEnabled:Bool?, iconData:String?,into context:Meow.MeowDatabase)  throws -> EventLoopFuture<MDTApplication> {
    if let name = name {
        app.name = name
    }
    if let description = description {
        app.description = description
    }
    if let maxVersionCheckEnabled = maxVersionCheckEnabled {
        //already enabled : Do nothing
        if maxVersionCheckEnabled  && app.maxVersionSecretKey == nil{
            app.maxVersionSecretKey = random(15)
        }
        
        if !maxVersionCheckEnabled {
            app.maxVersionSecretKey = nil
        }
    }
    var base64Icon = iconData
    if base64Icon?.isEmpty == true {
        app.base64IconData = nil
        base64Icon = nil
    }
    
    let savedClosure = { return app.save(to: context).map{ app }}
    if let base64Icon = base64Icon {
        return ImageDto.create(within: context.eventLoop, base64Image: base64Icon)
            .map{icon in
                guard let _ = icon  else { throw ApplicationError.invalidIconFormat }
                app.base64IconData = base64Icon
            }
            .flatMap{  return savedClosure() }
        
    }else {
        return savedClosure()
    }
}

/*
func updateApplication(from app:MDTApplication, maxVersionCheckEnabled:Bool?, iconData:String?){
    updateApplication(from: app, with:ApplicationUpdateDto(maxVersion: maxVersionCheckEnabled, iconData: iconData))
}

func updateApplication(from app:MDTApplication, with appDto:ApplicationUpdateDto){
    app.name = appDto.name ?? app.name
    app.description = appDto.description ?? app.description
    if let base64 = appDto.base64IconData {
        app.base64IconData = base64.isEmpty ? nil : base64
    }
  // app.base64IconData = (appDto.base64IconData?.isEmpty ?? false) ?     ?? app.base64IconData
    if let maxVersionCheckEnabled = appDto.maxVersionCheckEnabled {
        //already enabled : Do nothing
        if maxVersionCheckEnabled  && app.maxVersionSecretKey == nil{
            app.maxVersionSecretKey = random(15)
        }
        
        if !maxVersionCheckEnabled {
            app.maxVersionSecretKey = nil
        }
        
    }
}*/

func saveApplication(app:MDTApplication,into context:Meow.MeowDatabase) -> EventLoopFuture<MDTApplication>{
    return app.save(to: context).map{app}
}

func deleteApplication(by app:MDTApplication,into context:Meow.MeowDatabase) -> EventLoopFuture<Void>{
    return context.delete(app)
}

func deleteApplication(with name:String, and platform:Platform, into context:Meow.MeowDatabase) throws -> EventLoopFuture<Void>{
    return context.deleteOne(MDTApplication.self, where: Query.and([Query.valEquals(field: "name", val: name),Query.valEquals(field: "platform", val: platform.rawValue)]))
        .map({ count -> () in
            guard count == 1 else { throw ApplicationError.notFound }
        })
}

func generatePermanentLink(with info:MDTApplication.PermanentLink, into context:Meow.MeowDatabase) throws -> EventLoopFuture<TokenInfo> {
    let permanentLinkInfoData = try JSONEncoder().encode(info)
    let dictValues = try JSONSerialization.jsonObject(with: permanentLinkInfoData, options: []) as! [String:String]
    let valitidyInSecs = TimeInterval(info.validity*3600*24) // in days
    return storeTokenInfo(info: dictValues, durationInSecs: valitidyInSecs, into: context)
}
/*
func retrievePermanentLink(app:MDTApplication, with info:TokenInfo, into context:Meow.Context) throws -> Future<(MDTApplication.PermanentLink,Artifact?)?> {
    return findInfo(with: info.uuid, into: context).flatMap { dict in
        guard let dict = dict else { return context.eventLoop.newSucceededFuture(result: nil)}
        let permanentLink = try JSONDecoder().decode(MDTApplication.PermanentLink.self, from: try JSONSerialization.data(withJSONObject: dict, options: []))
        return searchMaxArtifact(app: app, branch: permanentLink.branch, artifactName: permanentLink.artifactName, into: context)
         /*   .map{ artifact in
                guard let artifact = artifact else { return nil}
                return PermanentLinkDto(from: permanentLink, artifact: artifact, installUrl: "TODO", installPageUrl: "TODO")
        }*/
    }
}*/

func retrievePermanentLinkArtifact(token:MDTApplication.TokenLink, into context:Meow.MeowDatabase) throws -> EventLoopFuture<(MDTApplication.TokenLink,Artifact?)> {
    return try findApplication(uuid: token.link.applicationUuid, into: context)
        .flatMap { app in
            guard let app = app else { throw ApplicationError.notFound }
            return searchMaxArtifact(app: app, branch: token.link.branch, artifactName: token.link.artifactName, into: context)
                .map { artifact in
                    return (token,artifact)
            }
    }
}


func retriveTokenInfo(tokenId:String, into context:Meow.MeowDatabase) throws -> EventLoopFuture<MDTApplication.TokenLink> {
    return findInfo(with: tokenId, into: context)
        .map{ dict in
            guard let dict = dict else { throw ApplicationError.expiredLink}
            return dict
        }
        .map { MDTApplication.TokenLink(tokenId: tokenId, link: try JSONDecoder().decode(MDTApplication.PermanentLink.self, from: try JSONSerialization.data(withJSONObject: $0, options: [])))}
}

func retrievePermanentLinks(app:MDTApplication, into context:Meow.MeowDatabase) throws -> EventLoopFuture<[(MDTApplication.TokenLink,Artifact?)]> {
    return (app.permanentLinks ?? []).map { $0.resolve(in: context) }.flatten(on: context)
        .flatMap { allTokens throws in
            let validLinks = try allTokens.filter{!$0.isExpired}
                .map { MDTApplication.TokenLink(tokenId: $0.uuid, link: try JSONDecoder().decode(MDTApplication.PermanentLink.self, from: try JSONSerialization.data(withJSONObject: $0.value, options: [])))}
            
            return try validLinks.map{ try retrievePermanentLinkArtifact(token: $0, into: context) }
            .flatten(on: context)
        }
}


func checkPermanentsLinks(app:MDTApplication, into context:Meow.MeowDatabase) throws -> EventLoopFuture<MDTApplication> {
    let checkLink = { (reference:Reference<TokenInfo>) -> Future<Reference<TokenInfo>?> in
        return reference.resolve(in: context)
            .map { tokenInfo in
                return tokenInfo.isExpired ? nil : reference
            }
    }
    
    return  (app.permanentLinks ?? []).map { checkLink($0) }.flatten(on: context)
        .flatMap { references in
            app.permanentLinks = references.compactMap { $0 }
            return saveApplication(app: app, into: context)
        }
}
/*
func retrievePermanentLink(app:MDTApplication, with reference:Reference<TokenInfo>, into context:Meow.Context) -> Future<Artifact?> {
    return reference.resolveIfPresent(in: context).flatMap({tokenInfo -> Future<Artifact?> in
        guard let tokenInfo = tokenInfo else { return context.eventLoop.newSucceededFuture(result: nil)}
        return try retrievePermanentLink(app: app, with: tokenInfo, into: context)
    })
}*/


extension MDTApplication {
    func removeAdmin(user:User, into context:Meow.MeowDatabase)throws -> EventLoopFuture<MDTApplication>{
        adminUsers.removeAll { reference -> Bool in
            return reference.reference == user._id
        }
        return save(to: context).map{self}
    }
    
    func isAlreadyAdmin(user:User) -> Bool {
        return adminUsers.contains(Reference(to: user))
    }
    
    func addAdmin(user:User, into context:Meow.MeowDatabase)throws -> EventLoopFuture<MDTApplication>{
        guard !isAlreadyAdmin(user: user) else { return context.eventLoop.newSucceededFuture(result: self)}
        adminUsers.append(Reference(to: user))
        return save(to: context).map{self}
    }
}
