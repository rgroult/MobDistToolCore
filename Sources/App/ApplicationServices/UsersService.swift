//
//  UserService.swift
//  App
//
//  Created by Rémi Groult on 25/02/2019.
//

import Vapor
import Meow
import CryptoSwift

enum UserError: Error {    
    case notFound
    case invalidLoginOrPassword
}

extension UserError: Debuggable {
    var reason: String {
        switch self {
        case .invalidLoginOrPassword:
            return "invalidLoginOrPassword"
        case .notFound:
            return "notFound"
        }
    }
    
    var identifier: String {
        return "UserError"
    }
}


func findUser(by email:String,into context:Meow.Context) throws -> Future<User?>{
    return context.find(User.self, where:  Query.valEquals(field: "email", val: email))
        .getFirstResult()
}

func findUser(by email:String, and password:String, updateLastLogin:Bool = true,into context:Meow.Context) throws  -> Future<User>{
    return try findUser(by: email, into: context)
        .flatMap{user in
            guard let user = user else { throw UserError.invalidLoginOrPassword }
            //check password
            guard checkPassword(plain: password, salt: user.salt, hash: user.password) else { throw UserError.invalidLoginOrPassword }
            
            if updateLastLogin {
                user.lastLogin = Date()
                return user.save(to: context).map{user}
            }else {
                return context.eventLoop.newSucceededFuture(result: user)
            }

        }
}

func createSysAdminIfNeeded(into context:Meow.Context,with config:MdtConfiguration) throws -> Future<Bool>{
    return context.findOne(User.self,where: Query.valEquals(field: "isSystemAdmin", val: true))
        .flatMap({ user  in
            if let _ = user {
                return context.eventLoop.newSucceededFuture(result: false)
            }else {
                //create Admin user
                let document  = ["email" : config.initialAdminEmail] as Document
                
                let adminUser = try BSONDecoder().decode(User.self, from: document)
                adminUser.isActivated = true
                let salt = generateSalt()
                adminUser.salt = salt
                adminUser.email = config.initialAdminEmail
                adminUser.password = generateHashedPassword(plain: config.initialAdminPassword,salt: salt)
                return adminUser.save(to: context).map{ true}
            }
        })
    
//    let config = try into.make(Config.self)
//    return into.make(Meow.Context.self)
//        .flatMap{ context in
//            return context
//    }
//
   // throw Abort(.custom(code: 500, reasonPhrase: "Not Implemented"))
}

private func checkPassword(plain:String,salt:String,hash:String) -> Bool{
    
    return generateHashedPassword(plain: plain, salt: salt) == hash
}

private func generateSalt() -> String {
    return UUID().description
}

private func generateHashedPassword(plain:String,salt:String) -> String {
    return "\(plain):\(salt)".md5()
}
