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
import JWT
import JWTAuth
import SwiftSMTP

enum RegistrationError : Error {
    case invalidEmailFormat, emailDomainForbidden
}

final class UsersController:BaseController {
    /*  override var  controllerVersion = "v2"
     var pathPrefix = "Users"
     */
    init(apiBuilder:OpenAPIBuilder) {
        super.init(version: "v2", pathPrefix: "Users", apiBuilder: apiBuilder)
    }
    
    func register(_ req: Request) throws -> Future<UserDto> {
        let config = try req.make(MdtConfiguration.self)
        return try req.content.decode(RegisterDto.self)
            .flatMap{ registerDto -> Future<UserDto>  in
                guard registerDto.email.isValidEmail() else { throw RegistrationError.invalidEmailFormat}
                
                //check in white domains
                if let whiteDomains = config.registrationWhiteDomains, whiteDomains.isEmpty {
                    if whiteDomains.firstIndex(where: {registerDto.email.hasSuffix($0)}) == nil {
                        throw RegistrationError.emailDomainForbidden
                    }
                }
                //register user
                let needRegistrationEmail = !config.automaticRegistration
                let context = try req.context()
                
                return try createUser(name: registerDto.name, email: registerDto.name, password: registerDto.password, isActivated:!needRegistrationEmail, into: context)
                    .flatMap{ user in
                        let userCreated = UserDto.create(from: user, content: ModelVisibility.full)
                        if needRegistrationEmail {
                            //sent registration email
                            let emailService = try req.make(EmailService.self)
                            return try emailService.sendValidationEmail(for: user, into: req).map{
                                userCreated }
                                .catchFlatMap({ error -> Future<UserDto> in
                                    //delete create user
                                    return try delete(user: user, into: context).map{
                                        throw error
                                    }
                                })
                        }else {
                            return req.eventLoop.newSucceededFuture(result: userCreated)
                        }
                        
                }
        }
    }
    
    func forgotPassword(_ req: Request) throws -> Future<String> {
        throw Abort(.custom(code: 500, reasonPhrase: "Not Implemented"))
    }
    
    func login(_ req: Request) throws -> Future<LoginRespDto> {
        return try req.content.decode(LoginReqDto.self)
        .flatMap{ loginDto -> Future<LoginRespDto>  in
             return req.meow().flatMap{context in
                return try findUser(by: loginDto.email, and: loginDto.password, updateLastLogin: true, into: context)
                    .flatMap({ user in
                        //generate token in header
                        let signers = try req.make(JWTSigners.self)
                        return try signers.get(kid: signerIdentifier, on: req)
                            .map{ signer in
                                let jwt = JWT(header: .init(kid: signerIdentifier), payload: JWTTokenPayload(email: user.email))
                                let signatureData = try jwt.sign(using: signer)
                                let token = String(bytes: signatureData, encoding: .utf8)!
                                return LoginRespDto( email: user.email, name: user.name,token:token)
                        }
                    })
            }
        }
    }
//    func loginOLD(_ req: Request) throws -> Future<LoginRespDto> {
//        return try req.content.decode(LoginReqDto.self)
//            .flatMap({ loginDto -> Future<LoginRespDto>  in
//                return req.meow().flatMap{context in
//                    return context.find(User.self, where:  Query.valEquals(field: "email", val: loginDto.email)).getFirstResult()
//                        .flatMap({ user in
//                            guard let user = user else { throw Abort(.notFound)}
//                            //generate token in header
//                            let signers = try req.make(JWTSigners.self)
//                            return try signers.get(kid: signerIdentifier, on: req)
//                                .map{ signer in
//                                    let jwt = JWT(header: .init(kid: signerIdentifier), payload: JWTTokenPayload(email: user.email))
//                                    let signatureData = try jwt.sign(using: signer)
//                                    let token = String(bytes: signatureData, encoding: .utf8)!
//                                    return LoginRespDto( email: user.email, name: user.name,token:token)
//                            }
//                        })
//                }
//            })
//    }
    
    func me(_ req: Request) throws -> Future<UserDto> {
        return try retrieveUser(from:req)
            .map{ user in
                guard let user = user else { throw Abort(.unauthorized)}
                return UserDto.create(from: user, content: .full)
        }
    }
    
    /*
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
     }*/
    /*
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
     }*/
    
    /*
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
     }*/
}
//extension Array : PrimitiveConvertible {}
/*
 db.getCollection("MDTApplication").find({ "adminUsers": { $elemMatch: {$eq: ObjectId("575984927f637070cbd41360") } } })
 */
