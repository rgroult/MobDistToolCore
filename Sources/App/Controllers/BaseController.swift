//
//  BaseController.swift
//  App
//
//  Created by Rémi Groult on 20/02/2019.
//

import Foundation
import Vapor
import Swiftgger
import Meow

protocol APIBuilderControllerProtocol {
    func generateOpenAPI(apiBuilder:OpenAPIBuilder)
}

class BaseController {
    static var basePathPrefix = ""
    var basePathPrefix:String {
        return BaseController.basePathPrefix
    }
    let controllerVersion:String
    let pathPrefix:String
    
    func generateRoute(_ verb:String)->String{
        return "\(basePathPrefix)/\(controllerVersion)/\(pathPrefix)/\(verb)"
    }
    
    init(version:String,pathPrefix:String,apiBuilder:OpenAPIBuilder?){
        self.controllerVersion = version
        self.pathPrefix = pathPrefix
        if let builder = apiBuilder, let builderController = self as? APIBuilderControllerProtocol {
            builderController.generateOpenAPI(apiBuilder:builder)
        }
    }
    
    func retrieveUser(from req:Request) throws -> EventLoopFuture<User?>  {
        let jwt = try req.authenticated(JWTTokenPayload.self)
        guard let email = jwt?.email else { throw Abort(.notFound)}
        let context = try req.meow
        //let context = try req.context()
        return context.findOne(User.self, where: Query.valEquals(field: "email", val: email))
    }
    
    func retrieveMandatoryUser(from req:Request) throws -> EventLoopFuture<User> {
        return try retrieveUser(from: req)
        .flatMapThrowing{ user in
            guard let user = user else { throw Abort(.unauthorized)}
            return user
        }
    }
    
    func retrieveMandatoryAdminUser(from req:Request) throws -> EventLoopFuture<User> {
        return try retrieveMandatoryUser(from: req)
            .flatMapThrowing{ user in
                guard user.isSystemAdmin else { throw UserError.userNotAdministrator }
                return user
        }
    }
    
    func extractSearch(from req:Request,searchField:String)  throws -> Query? {
        guard let searchValue = try? req.query.get(String.self, at: "searchby") else { return nil}
        let query: Document = [searchField : ["$regex": searchValue,"$options": "i"]]
        return Query.custom(query)
    }
    
    func generatePaginationParameters(sortby:[String],searchByField:String?) ->  [APIParameter] {
        var commonParams = [
            APIParameter(name: "per", parameterLocation:.query, description: "Number of results per page : default \(MappedCursorDefaultPageSize)", required: false),
            APIParameter(name: "page", parameterLocation:.query, description: "Page number required : default 0", required: false),
            APIParameter(name: "orderby", parameterLocation:.query, description: "Order results : \(PaginationSort.descending)[Default] , \(PaginationSort.ascending)", required: false)
        ]
        if let searchByField = searchByField {
            commonParams.append(APIParameter(name: "searchby", parameterLocation:.query, description: "Search into \(searchByField)", required: false))
        }
        if !sortby.isEmpty {
            commonParams.append(APIParameter(name: "sortby", parameterLocation:.query, description: "Possible sort fields: \(sortby.first ?? "")[default] \(sortby.suffix(from: 1).joined(separator: ", "))", required: false))
        }
        
        return commonParams
    }
    
    func track(event:ActivityEvent, for req:Request){
        let trackingService = try? req.make(MdtActivityFileLogger.self)
        trackingService?.track(event: event)
    }
}
