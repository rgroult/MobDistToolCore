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
}

extension ApplicationError:Debuggable {
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
        }
    }
    
    var identifier: String {
        return "ApplicationError"
    }
}

func findApplications(platform:Platform? = nil ,into context:Meow.Context,additionalQuery:Query?) throws -> (Query?,MappedCursor<FindCursor, MDTApplication>){
    let query:Query
    let anotherQuery = additionalQuery ?? Query()
    if let platorm = platform {
        query = Query.and([anotherQuery,Query.valEquals(field: "platform", val: platorm.rawValue)])
    }else {
        query = anotherQuery
    }
    return (query,context.find(MDTApplication.self,where:query))
}

func findApplications(for user:User, into context:Meow.Context) throws  -> MappedCursor<FindCursor, MDTApplication>{
    let query: Document = ["$eq": user._id]
    return context.find(MDTApplication.self, where: Query.containsElement(field: "adminUsers", match: Query.custom(query)))
}

func findApplication(name:String,platform:Platform,into context:Meow.Context) throws -> Future<MDTApplication?> {
    return context.findOne(MDTApplication.self, where: Query.and([Query.valEquals(field: "name", val: name),Query.valEquals(field: "platform", val: platform.rawValue)]))
}

func findApplication(apiKey:String,into context:Meow.Context) throws -> Future<MDTApplication?> {
    return context.findOne(MDTApplication.self, where:Query.valEquals(field: "apiKey", val: apiKey))
}

func findApplication(uuid:String,into context:Meow.Context) throws -> Future<MDTApplication?> {
    return context.findOne(MDTApplication.self, where: Query.valEquals(field: "uuid", val: uuid))
}

func createApplication(name:String,platform:Platform,description:String,adminUser:User, base64Icon:String? = nil,into context:Meow.Context) throws -> Future<MDTApplication> {
    return try findApplication(name: name, platform: platform, into: context)
        .flatMap({ app  in
            guard app == nil else { throw ApplicationError.alreadyExist }
            
            return ImageDto.create(within: context.eventLoop, base64Image: base64Icon)
                .flatMap({icon in
                    //base64Icon AND icon ?
                    if let _ = base64Icon {
                        guard let _ = icon  else { throw ApplicationError.invalidIconFormat }
                    }
                    let createdApplication = MDTApplication(name: name, platform: platform, adminUser: adminUser, description: description, base64Icon: base64Icon)
                    return  createdApplication.save(to: context).map{ createdApplication}
                })
            /*
            if let iconData = base64Icon {
                guard let _ = ImageDto(from: iconData) else { throw ApplicationError.invalidIconFormat }
            }
            let createdApplication = MDTApplication(name: name, platform: platform, adminUser: adminUser, description: description, base64Icon: base64Icon)
            return  createdApplication.save(to: context).map{ createdApplication}*/
        })
}

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
}

func saveApplication(app:MDTApplication,into context:Meow.Context) -> Future<MDTApplication>{
    return app.save(to: context).map{app}
}

func deleteApplication(by app:MDTApplication,into context:Meow.Context) -> Future<Void>{
    return context.delete(app)
}

func deleteApplication(with name:String, and platform:Platform, into context:Meow.Context) throws -> Future<Void>{
    return context.deleteOne(MDTApplication.self, where: Query.and([Query.valEquals(field: "name", val: name),Query.valEquals(field: "platform", val: platform.rawValue)]))
        .map({ count -> () in
            guard count == 1 else { throw ApplicationError.notFound }
        })
}

extension MDTApplication {
    func removeAdmin(user:User, into context:Meow.Context)throws -> Future<MDTApplication>{
        adminUsers.removeAll { reference -> Bool in
            return reference.reference == user._id
        }
        return save(to: context).map{self}
    }
    
    func isAlreadyAdmin(user:User) -> Bool {
        return adminUsers.contains(Reference(to: user))
    }
    
    func addAdmin(user:User, into context:Meow.Context)throws -> Future<MDTApplication>{
        guard !isAlreadyAdmin(user: user) else { return context.eventLoop.newSucceededFuture(result: self)}
        adminUsers.append(Reference(to: user))
        return save(to: context).map{self}
    }
}
