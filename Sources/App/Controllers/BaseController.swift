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
    let controllerVersion:String
    let pathPrefix:String
    
    func generateRoute(_ verb:String)->String{
        return "/\(controllerVersion)/\(pathPrefix)/\(verb)"
    }
    
    init(version:String,pathPrefix:String,apiBuilder:OpenAPIBuilder?){
        self.controllerVersion = version
        self.pathPrefix = pathPrefix
        if let builder = apiBuilder, let builderController = self as? APIBuilderControllerProtocol {
            builderController.generateOpenAPI(apiBuilder:builder)
        }
    }
    
    func retrieveUser(from req:Request) throws -> Future<User?>  {
        let jwt = try req.authenticated(JWTTokenPayload.self)
        guard let email = jwt?.email else { throw Abort(.notFound)}
        let context = try req.context()
        return context.findOne(User.self, where: Query.valEquals(field: "email", val: email))
    }
    
    
    /*
    func generateOpenAPI(apiBuilder:OpenAPIBuilder){
        
    }*/
}
