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
    case notActivated
    case alreadyExist
    case invalidLoginOrPassword
    case userNotAdministrator
    case fieldInvalid(fieldName:String)
    case invalidPassworsStrength(required:Int)
}

extension UserError: Debuggable {
    var reason: String {
        switch self {
        case .invalidLoginOrPassword:
            return "UserError.invalidLoginOrPassword"
        case .notFound:
            return "UserError.notFound"
        case .fieldInvalid(let fieldName):
            return "UserError.fieldInvalid:\(fieldName)"
        case .alreadyExist:
            return "UserError.alreadyPresent"
        case .notActivated:
            return "UserError.notActivated"
        case .userNotAdministrator:
            return "UserError.userNotAdministrator"
        case .invalidPassworsStrength:
            return "UserError.invalidPassworsStrength"
        }
    }
    
    var identifier: String {
        return "UserError"
    }
}

func allUsers(into context:Meow.Context,additionalQuery:Query?) throws -> MappedCursor<FindCursor, User>{
    return context.find(User.self, where: additionalQuery ?? Query())
}

func findActivableUser(by activationToken:String,into context:Meow.Context) throws -> Future<User?>{
    return context.find(User.self, where:  Query.valEquals(field: "activationToken", val: activationToken))
        .getFirstResult()
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
        //createdUser.createdAt = Date()
        if !isActivated {
            //generate activation token
            createdUser.activationToken = UUID().uuidString
        }
        return createdUser.save(to: context).map{ createdUser}
    }
}

func updateUser(user:User, newName:String?,newPassword:String?, newFavoritesApplicationsUUID:[String]? ,isSystemAdmin:Bool?,isActivated:Bool?, into context:Meow.Context) throws -> Future<User>{
    if let name = newName {
        user.name = name
    }
    if let password = newPassword {
        user.password = generateHashedPassword(plain: password,salt: user.salt)
    }
    if let isSystemAdmin = isSystemAdmin {
        user.isSystemAdmin = isSystemAdmin
    }
    if let isActivated = isActivated {
        user.isActivated = isActivated
    }
    if let favoritesApplicationsUUID = newFavoritesApplicationsUUID {
        if favoritesApplicationsUUID.isEmpty {
            user.favoritesApplicationsUUID?.removeAll()
        }
        else {
            do {
                let favoritesFlattenApplicationsUUID = String(data: try JSONEncoder().encode(favoritesApplicationsUUID), encoding: .utf8)
                user.favoritesApplicationsUUID = favoritesFlattenApplicationsUUID
            }catch {
                throw UserError.fieldInvalid(fieldName:"favoritesApplicationsUUID")
            }
        }
    }
    return user.save(to: context).map{user}
}

func activateUser(withToken:String, into context:Meow.Context) throws -> Future<User>{
    return try findActivableUser(by: withToken, into: context)
        .flatMap({ user in
            guard let user = user else { throw UserError.notFound }
            //activate user
            user.isActivated = true
            user.activationToken  = nil
            return user.save(to: context).map{user}
        })
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
    user.activationToken = UUID().uuidString
    user.isActivated = false
    return user.save(to: context).map{user}
}

private func checkPassword(plain:String,salt:String,hash:String) -> Bool{
    return generateHashedPassword(plain: plain, salt: salt) == hash
}

private func generateSalt() -> String {
    return UUID().uuidString
}

private func generateHashedPassword(plain:String,salt:String) -> String {
    return "\(plain):\(salt)".md5()
}
