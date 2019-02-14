//
//  UsersController.swift
//  App
//
//  Created by Rémi Groult on 12/02/2019.
//

import Vapor
import MeowVapor
import BSON
import Swiftgger

final class UsersController {
    let controllerVersion = "v2"
    func generateRoute(_ verb:String)->String{
        return "/\(controllerVersion)/Users/\(verb)"
    }
    init(apiBuilder:OpenAPIBuilder) {
        generateOpenAPI(apiBuilder: apiBuilder)
    }
    
    func register(_ req: Request) throws -> Future<String> {
        throw Abort(.custom(code: 500, reasonPhrase: "Not Implemented"))
    }
    
    func forgotPassword(_ req: Request) throws -> Future<String> {
        throw Abort(.custom(code: 500, reasonPhrase: "Not Implemented"))
    }
    
    func login(_ req: Request) throws -> Future<String> {
        throw Abort(.custom(code: 500, reasonPhrase: "Not Implemented"))
    }
    
    func index(_ req: Request) throws -> Future<[User]> {
        return req.meow().flatMap({ context -> Future<[User]> in
            // Start using Meow!
            return context.find(User.self).getAllResults()
        })
        //return Todo.query(on: req).all()
    }
    
    func apps(_ req: Request) throws -> Future<[MDTApplication]> {
        print("Retrieve Apps")
        
        
        return req.meow().flatMap({ context -> Future<[MDTApplication]> in
            // Start using Meow!
            return context.find(MDTApplication.self).getAllResults()
        })
    }
    
    func app(_ req: Request) throws -> Future<MDTApplication> {
        print("Retrieve first App")
        
        return req.meow().flatMap({ context -> Future<MDTApplication> in
            // Start using Meow!
            return context.find(MDTApplication.self).getFirstResult()
                .map({$0!})
        })
    }
    
    func test(_ req: Request) throws -> Future<MDTApplication2> {
        return req.meow().flatMap { context -> EventLoopFuture<MDTApplication2> in
            return context.find(User.self).getFirstResult().flatMap({ user in
                let appJson:Document = ["_id" : ObjectId() , "name" : "testAppNew"]
                let app = try MDTApplication2.decoder.decode(MDTApplication2.self, from: appJson)
                if let user = user {
                    app.adminUsers = [Reference(to: user)]
                }
                return app.save(to: context).map({_ in return app
                })
            })
        }
    }
    
    
    func artifacts(_ req: Request) throws -> Future<[Artifact]> {
        return req.meow().flatMap({ context -> Future<[Artifact]> in
            // Start using Meow!
            return context.find(Artifact.self).getAllResults()
        })
        //return Todo.query(on: req).all()
    }
    
    func findAppsForUser(_ req: Request) throws -> Future<[MDTApplication]> {
        guard let email = req.query[String.self, at: "email"] else {
            throw Abort(.badRequest)
        }
        
        return req.meow().flatMap {context -> Future<[MDTApplication]> in
            return context.findOne(User.self, where: Query.valEquals(field: "email", val: email))
                .flatMap({ user -> Future<[MDTApplication]> in
                    guard let user = user else {throw Abort(.badRequest)}
                    let query: Document = ["$eq": user._id]
                    return context.find(MDTApplication.self, where: Query.containsElement(field: "adminUsers", match: Query.custom(query))).getAllResults()
                })
        }
    }
}
//extension Array : PrimitiveConvertible {}
/*
 db.getCollection("MDTApplication").find({ "adminUsers": { $elemMatch: {$eq: ObjectId("575984927f637070cbd41360") } } })
 */
