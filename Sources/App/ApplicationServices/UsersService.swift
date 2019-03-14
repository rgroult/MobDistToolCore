//
//  UserService.swift
//  App
//
//  Created by Rémi Groult on 25/02/2019.
//

import Vapor
import Meow
import CryptoSwift

enum UserError: Error,Equatable {
    case notFound
    case alreadyExist
    case invalidLoginOrPassword
    case fieldInvalid(fieldName:String)
}

extension UserError: Debuggable {
    var reason: String {
        switch self {
        case .invalidLoginOrPassword:
            return "invalidLoginOrPassword"
        case .notFound:
            return "notFound"
        case .fieldInvalid(let fieldName):
            return "FieldInvalid:\(fieldName)"
        case .alreadyExist:
            return "alreadyPresent"
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
                return try createUser(name: "Admin", email: config.initialAdminEmail, password: config.initialAdminPassword, isSystemAdmin:true, isActivated: true, into: context)
                    .map{_ in  true}
            }
        })
}

func createUser(name:String,email:String,password:String,isSystemAdmin:Bool = false, isActivated:Bool = false , into context:Meow.Context) throws -> Future<User>{
    //find existing user
    return try findUser(by: email, into: context).flatMap { user in
        guard user == nil else { throw UserError.alreadyExist }
        
        //create  user
        let createdUser = User(email: email, name: name)
        createdUser.isActivated = isActivated
        createdUser.isSystemAdmin = isSystemAdmin
        let salt = generateSalt()
        createdUser.salt = salt
        createdUser.password = generateHashedPassword(plain: password,salt: salt)
        if !isActivated {
            //generate activation token
            createdUser.activationToken = UUID().description
        }
        return createdUser.save(to: context).map{ createdUser}
    }
}

func deleteUser(withEmail email:String, into context:Meow.Context) throws -> Future<Void>{
    return context.deleteOne(User.self, where: Query.valEquals(field: "email", val: email))
        .map({ count -> () in
            guard count == 1 else { throw UserError.notFound }
        })
}

func delete(user:User, into context:Meow.Context) throws -> Future<Void>{
    return context.delete(user)
}

func resetUser(user:User,newPassword:String,into context:Meow.Context) throws -> Future<User>{
    user.password = generateHashedPassword(plain: newPassword,salt: user.salt)
    //generate activation token
    user.activationToken = UUID().description
    user.isActivated = false
    return user.save(to: context).map{user}
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
