//
//  ApplicationService.swift
//  App
//
//  Created by Rémi Groult on 25/02/2019.
//

import Foundation
import Meow
import Vapor

let lastVersionBranchName = "@@@@LAST####"
let lastVersionName = "latest"

enum ApplicationError: Error, Equatable {
    case notFound
    case alreadyExist
    case notAnApplicationAdministrator
    case invalidApplicationAdministrator
    case deleteLastApplicationAdministrator
    case iconNotFound
    case invalidIconFormat
    case expirationTimestamp(delay: Int)
    case disabledFeature
    case invalidSignature
    case unknownPlatform
    case expiredLink
    case invalidLink
}

extension ApplicationError: DebuggableError {
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
        case .invalidLink:
            return "ApplicationError.invalidLink"
        }
    }

    var identifier: String {
        return "ApplicationError"
    }
}

func findApplicationsPaginated(platform: Platform? = nil, pagination: PaginationInfo, into context: Meow.MeowDatabase, additionalQuery: MongoKittenQuery?) -> EventLoopFuture<PaginationResult<MDTApplication>?> {
    let query: MongoKittenQuery
    let anotherQuery = additionalQuery ?? EmptyQuery()
    if let platorm = platform {
        query = anotherQuery &&  "platform" == platorm.rawValue //    Query.and([anotherQuery,Query.valEquals(field: "platform", val: platorm.rawValue)])
    } else {
        query = anotherQuery
    }

    return findWithPagination(stages: [["$match": query.makeDocument()]], paginationInfo: pagination, into: context.collection(for: MDTApplication.self).raw).firstResult()

    /*
        context.collection(for: MDTApplication.self).raw.find(query.makeDocument())
     //   return (query,context.collection(for: MDTApplication.self).find(where:query.makeDocument())) //   .find(MDTApplication.self,where:query))
        return (query,context.collection(for: MDTApplication.self).raw.find(query.makeDocument()))*/
}

func findApplications(with uuids: [String], into context: Meow.MeowDatabase) -> MappedCursor<FindQueryBuilder, MDTApplication> {
    // ex : db.getCollection('feed').find({"_id" : {"$in" : [ObjectId("55880c251df42d0466919268"), ObjectId("55bf528e69b70ae79be35006")]}});
    let query: Document = ["uuid": ["$in": uuids]]
    return context.collection(for: MDTApplication.self).find(where: query)
}

func findApplications(for user: User, into context: Meow.MeowDatabase) -> MappedCursor<FindQueryBuilder, MDTApplication> {
    // let query: Document = ["$eq": user._id]
    // find( { "adminUsers": { $elemMatch: { "$eq": user._id} } } )
    let query: Document = ["adminUsers": ["$elemMatch": ["$eq": user._id]]]
    // return context.find(MDTApplication.self, where: Query.containsElement(field: "adminUsers", match: Query.custom(query)))
    return context.collection(for: MDTApplication.self).find(where: query)
}

func findApplication(name: String, platform: Platform, into context: Meow.MeowDatabase) throws -> EventLoopFuture<MDTApplication?> {
    return context.collection(for: MDTApplication.self).findOne(where: "name" == name && "platform" == platform.rawValue)
    // return context.findOne(MDTApplication.self, where: Query.and([Query.valEquals(field: "name", val: name),Query.valEquals(field: "platform", val: platform.rawValue)]))
}

func findApplication(apiKey: String, into context: Meow.MeowDatabase) throws -> EventLoopFuture<MDTApplication?> {
    return context.collection(for: MDTApplication.self).findOne(where: "apiKey" == apiKey )
    // return context.findOne(MDTApplication.self, where:Query.valEquals(field: "apiKey", val: apiKey))
}

func findApplication(uuid: String, into context: Meow.MeowDatabase) -> EventLoopFuture<MDTApplication?> {
    return context.collection(for: MDTApplication.self).findOne(where: "uuid" == uuid)
    // return context.findOne(MDTApplication.self, where: Query.valEquals(field: "uuid", val: uuid))
}

func createApplication(name: String, platform: Platform, description: String, adminUser: User, base64Icon: String? = nil, maxVersionCheckEnabled: Bool? = nil, into context: Meow.MeowDatabase) throws -> EventLoopFuture<MDTApplication> {
    return try findApplication(name: name, platform: platform, into: context)
        .flatMap { app in
            do {
                guard app == nil else { throw ApplicationError.alreadyExist }
                let createdApplication = MDTApplication(name: name, platform: platform, adminUser: adminUser, description: description)
                return updateApplicationWithParameters(from: createdApplication, name: name, description: description, maxVersionCheckEnabled: maxVersionCheckEnabled, iconData: base64Icon, into: context)
            } catch {
                return context.eventLoop.makeFailedFuture(error)
            }
        }
}

func updateApplicationWithParameters(from app: MDTApplication, name: String?, description: String?, maxVersionCheckEnabled: Bool?, iconData: String?, into context: Meow.MeowDatabase) -> EventLoopFuture<MDTApplication> {
    if let name = name {
        app.name = name
    }
    if let description = description {
        app.description = description
    }
    if let maxVersionCheckEnabled = maxVersionCheckEnabled {
        // already enabled : Do nothing
        if maxVersionCheckEnabled, app.maxVersionSecretKey == nil {
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

    let savedClosure = { app.save(in: context).map { _ in app }}
    if let base64Icon = base64Icon {
        return ImageDto.create(within: context.eventLoop, base64Image: base64Icon)
            .flatMapThrowing { icon in
                guard let _ = icon else { throw ApplicationError.invalidIconFormat }
                app.base64IconData = base64Icon
            }
            .flatMap { savedClosure() }

    } else {
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

func saveApplication(app: MDTApplication, into context: Meow.MeowDatabase) -> EventLoopFuture<MDTApplication> {
    return app.save(in: context).map { _ in app }
}

func deleteApplication(by app: MDTApplication, into context: Meow.MeowDatabase) -> EventLoopFuture<Void> {
    return context.collection(for: MDTApplication.self).deleteOne(where: "_id" == app._id)
        .map { _ in }
    // return context.delete(app)
}

func deleteApplication(with name: String, and platform: Platform, into context: Meow.MeowDatabase) throws -> EventLoopFuture<Void> {
    return context.collection(for: MDTApplication.self).deleteOne(where: "name" == name && "platform" == platform.rawValue)
        .flatMapThrowing { deleteReplay in
            guard deleteReplay.deletes == 1 else { throw ApplicationError.notFound }
        }

    /*  return context.deleteOne(MDTApplication.self, where: Query.and([Query.valEquals(field: "name", val: name),Query.valEquals(field: "platform", val: platform.rawValue)]))
     .map({ count -> () in
     guard count == 1 else { throw ApplicationError.notFound }
     })*/
}

// MARK: - Permanent links

func generatePermanentLink(inside app: MDTApplication, with info: MDTApplication.PermanentLink2, into context: Meow.MeowDatabase) throws -> EventLoopFuture<TokenInfo> {
    guard let permanentLinkInfoString = String(data: try JSONEncoder().encode(info), encoding: .utf8) else { throw "Invalid content" }
    let dictValues = ["link": permanentLinkInfoString]
    let valitidyInSecs = TimeInterval(info.validity*3600*24) // in days
    return storeTokenInfo(info: dictValues, durationInSecs: valitidyInSecs, into: context)
        .flatMap { tokenInfo in
            app.addPermanentLink(link: tokenInfo, into: context)
                .map { _ in tokenInfo }
        }
}

func retrievePermanentLinkArtifact(tokenInfo: TokenInfo, into context: Meow.MeowDatabase) throws -> EventLoopFuture<(MDTApplication.PermanentLink2, Artifact?)> {
    guard !tokenInfo.isExpired else { throw ApplicationError.expiredLink }
    guard let stringValue = tokenInfo.value["link"], let data = stringValue.data(using: .utf8) else { throw "Invalid Content Saved" }
    let link = try JSONDecoder().decode(MDTApplication.PermanentLink2.self, from: data)
    return try retrieveArtifact(link: link, into: context).map{(link,$0)}
}

func retrieveArtifact(link: MDTApplication.PermanentLink2, into context: Meow.MeowDatabase) throws -> EventLoopFuture<Artifact?> {
    return findApplication(uuid: link.applicationUuid, into: context)
        .flatMap { app in
            do {
                guard let app = app else { throw ApplicationError.notFound }
                return searchMaxArtifact(app: app, branch: link.branch, artifactName: link.artifactName, into: context)
            } catch {
                return context.eventLoop.makeFailedFuture(error)
            }
        }
}
/*
func retrieveTokenInfo(tokenId: String, into context: Meow.MeowDatabase) throws -> EventLoopFuture<MDTApplication.PermanentLink2> {
    return findInfo(with: tokenId, into: context)
        .flatMapThrowing { dict in
            guard let dict = dict else { throw ApplicationError.expiredLink }
            return dict
        }
        .flatMapThrowing { try JSONDecoder().decode(MDTApplication.PermanentLink.self, from: try JSONSerialization.data(withJSONObject: $0, options: []))) }
}*/

func checkPermanentsLinks(app: MDTApplication, into context: Meow.MeowDatabase) throws -> EventLoopFuture<MDTApplication> {
    let checkLink = { (reference: Reference<TokenInfo>) -> EventLoopFuture<Reference<TokenInfo>?> in
        reference.resolve(in: context)
            .map { tokenInfo in
                tokenInfo.isExpired ? nil : reference
            }
    }

    return (app.permanentLinks ?? []).map { checkLink($0) }.flatten(on: context.eventLoop)
        .flatMap { references in
            app.permanentLinks = references.compactMap { $0 }
            return saveApplication(app: app, into: context)
        }
}

struct PermanentLinkInfo {
    let tokenId:String
    let link:MDTApplication.PermanentLink2
    let artifact:Artifact?
}

func retrievePermanentLinks(app: MDTApplication, into context: Meow.MeowDatabase) -> EventLoopFuture<[PermanentLinkInfo]> {
    var links = [Reference<TokenInfo>]() //app.permanentLinks ?? []
    
    let retrieveInfo = { (reference: Reference<TokenInfo>) -> EventLoopFuture<PermanentLinkInfo?> in
        return reference.resolve(in: context)
            .flatMap{ tokenInfo in
                do {
                    return try retrievePermanentLinkArtifact(tokenInfo: tokenInfo, into: context).map{(link,artifact) in
                        links.append(Reference(to:tokenInfo))
                        return PermanentLinkInfo(tokenId: tokenInfo.uuid, link: link, artifact: artifact) }
                }catch {
                    return context.eventLoop.makeSucceededFuture(nil)
                }
            }
    }
    
    return (app.permanentLinks ?? []).map{ retrieveInfo($0)}
        .flatten(on: context.eventLoop)
        .flatMap { permanentLinks in
            app.permanentLinks = links
            return app.save(in: context).map { _ in permanentLinks.compactMap{$0} }
        }
    
    /*
    return links.map{ $0.resolve(in: context) }.flatten(on: context.eventLoop)
        .flatMap{ tokenInfoArray in
            tokenInfoArray.map{ tokenInfo in
                
            }
            
            do {
                return retrievePermanentLinkArtifact(tokenInfo: tokenInfo, into: context)
                    .map{ PermanentLinkInfo(tokenId: tokenInfo, link: $0, artifact: $1) }
            }catch {
                return context.eventLoop.makeSucceededFuture(nil)
            }
        }*/
}
/*
func retrievePermanentLinks(app: MDTApplication, into context: Meow.MeowDatabase) -> EventLoopFuture<[(MDTApplication.TokenLink, Artifact?)]> {
    return try checkPermanentsLinks(app: app, into: meow)
        .flatMap({ application in
            return (app.permanentLinks ?? []).map { $0.resolve(in: context) }.flatten(on: context.eventLoop)
                .flatMap { allTokens in
                    allTokens.map {token in
                        return retrievePermanentLinkArtifact(tokenInfo: TokenInfo, into: meow)
                            .map {
                                
                            }
                    }
                }
        })
    
    
    return (app.permanentLinks ?? []).map { $0.resolve(in: context) }.flatten(on: context.eventLoop)
        .flatMap { allTokens in
            do {
                let validLinks = try allTokens.filter { !$0.isExpired }
                    .map { MDTApplication.TokenLink(tokenId: $0.uuid, link: try JSONDecoder().decode(MDTApplication.PermanentLink.self, from: try JSONSerialization.data(withJSONObject: $0.value, options: []))) }

                return try validLinks.map { retrievePermanentLinkArtifact(token: $0, into: context) }
                    .flatten(on: context.eventLoop)
            } catch {
                return context.eventLoop.makeFailedFuture(error)
            }
        }
}


*/





/*

func generatePermanentLink(inside app: MDTApplication, with info: MDTApplication.PermanentLink, into context: Meow.MeowDatabase) throws -> EventLoopFuture<TokenInfo> {
    let permanentLinkInfoData = try JSONEncoder().encode(info)
    let dictValuesAny = try JSONSerialization.jsonObject(with: permanentLinkInfoData, options: []) as! [String: Any]
    let dictValues: [String: String] = dictValuesAny.mapValues { $0 is String ? $0 as! String : "\($0)" }
    let valitidyInSecs = TimeInterval(info.validity*3600*24) // in days
    return storeTokenInfo(info: dictValues, durationInSecs: valitidyInSecs, into: context)
        .flatMap { tokenInfo in
            app.addPermanentLink(link: tokenInfo, into: context)
                .map { _ in tokenInfo }
        }
}*/

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


/*
 TO KEEEP ?
 
func retrievePermanentLinkArtifact(token: MDTApplication.TokenLink, into context: Meow.MeowDatabase) -> EventLoopFuture<(MDTApplication.TokenLink, Artifact?)> {
    return findApplication(uuid: token.link.applicationUuid, into: context)
        .flatMap { app in
            do {
                guard let app = app else { throw ApplicationError.notFound }
                return searchMaxArtifact(app: app, branch: token.link.branch, artifactName: token.link.artifactName, into: context)
                    .map { artifact in
                        (token, artifact)
                    }
            } catch {
                return context.eventLoop.makeFailedFuture(error)
            }
        }
}

func retriveTokenInfo(tokenId: String, into context: Meow.MeowDatabase) throws -> EventLoopFuture<MDTApplication.TokenLink> {
    return findInfo(with: tokenId, into: context)
        .flatMapThrowing { dict in
            guard let dict = dict else { throw ApplicationError.expiredLink }
            return dict
        }
        .flatMapThrowing { MDTApplication.TokenLink(tokenId: tokenId, link: try JSONDecoder().decode(MDTApplication.PermanentLink.self, from: try JSONSerialization.data(withJSONObject: $0, options: []))) }
}

func retrievePermanentLinks(app: MDTApplication, into context: Meow.MeowDatabase) -> EventLoopFuture<[(MDTApplication.TokenLink, Artifact?)]> {
    return (app.permanentLinks ?? []).map { $0.resolve(in: context) }.flatten(on: context.eventLoop)
        .flatMap { allTokens in
            do {
                let validLinks = try allTokens.filter { !$0.isExpired }
                    .map { MDTApplication.TokenLink(tokenId: $0.uuid, link: try JSONDecoder().decode(MDTApplication.PermanentLink.self, from: try JSONSerialization.data(withJSONObject: $0.value, options: []))) }

                return try validLinks.map { retrievePermanentLinkArtifact(token: $0, into: context) }
                    .flatten(on: context.eventLoop)
            } catch {
                return context.eventLoop.makeFailedFuture(error)
            }
        }
}

*/

/*
 func retrievePermanentLink(app:MDTApplication, with reference:Reference<TokenInfo>, into context:Meow.Context) -> Future<Artifact?> {
 return reference.resolveIfPresent(in: context).flatMap({tokenInfo -> Future<Artifact?> in
 guard let tokenInfo = tokenInfo else { return context.eventLoop.newSucceededFuture(result: nil)}
 return try retrievePermanentLink(app: app, with: tokenInfo, into: context)
 })
 }*/

// MARK: - usefull Extension MDTApplication

extension MDTApplication {
    func removeAdmin(user: User, into context: Meow.MeowDatabase) throws -> EventLoopFuture<MDTApplication> {
        adminUsers.removeAll { reference -> Bool in
            reference.reference == user._id
        }
        return save(in: context).map { _ in self }
    }

    func isAlreadyAdmin(user: User) -> Bool {
        return adminUsers.contains(Reference(to: user))
    }

    func addAdmin(user: User, into context: Meow.MeowDatabase) throws -> EventLoopFuture<MDTApplication> {
        guard !isAlreadyAdmin(user: user) else { return context.eventLoop.makeSucceededFuture(self) }
        adminUsers.append(Reference(to: user))
        return save(in: context).map { _ in self }
    }

    func addPermanentLink(link: TokenInfo, into context: Meow.MeowDatabase) -> EventLoopFuture<MDTApplication> {
        var links = permanentLinks ?? []
        links.append(Reference(to: link))
        permanentLinks = links
        return save(in: context).map { _ in self }
    }
    
    func removePermanentLink(link: TokenInfo, into context: Meow.MeowDatabase) -> EventLoopFuture<MDTApplication> {
        permanentLinks?.removeAll { reference -> Bool in
            reference.reference == link._id
        }
        return save(in: context).map { _ in self }
    }
}
