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

extension UserError: DebuggableError {
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

func allUsersPaginated(into context:Meow.MeowDatabase,additionalQuery:MongoKittenQuery?, paginationInfo:PaginationInfo) -> EventLoopFuture<PaginationResult<User>?> /*FindQueryBuilder*/ {
    let query = additionalQuery?.makeDocument() ?? [:]
    return findWithPagination(stages: [["$match": query]], paginationInfo: paginationInfo, into: context.collection(for: User.self).raw).firstResult()
    
    //return context.collection(for: User.self).raw.find(additionalQuery?.makeDocument() ?? [:])
}

func findActivableUser(by activationToken:String,into context:Meow.MeowDatabase) -> EventLoopFuture<User?>{
    return context.collection(for: User.self).find(where: "activationToken" == activationToken)
        .firstResult()
}

func findUser(by email:String,into context:Meow.MeowDatabase) -> EventLoopFuture<User?>{
    return context.collection(for: User.self).find(where: "email" == email).firstResult()
    //return context.find(User.self, where:  Query.valEquals(field: "email", val: email))
     //   .getFirstResult()
}

func findUser(by email:String, and password:String, updateLastLogin:Bool = true,into context:Meow.MeowDatabase)  -> EventLoopFuture<User>{
    return findUser(by: email, into: context)
        .flatMap{user in
            guard let user = user else { return context.eventLoop.makeFailedFuture(UserError.invalidLoginOrPassword)}
            //{ throw UserError.invalidLoginOrPassword }
            //check password
            guard checkPassword(plain: password, salt: user.salt, hash: user.password) else { return context.eventLoop.makeFailedFuture(UserError.invalidLoginOrPassword)}
            //{ throw UserError.invalidLoginOrPassword }
            
            if updateLastLogin {
                user.lastLogin = Date()
                return user.save(in: context).map{_ in user}
            }else {
                return context.eventLoop.makeSucceededFuture(user)
            }
        }
}

func createSysAdminIfNeeded(into context:Meow.MeowDatabase,with config:MdtConfiguration) -> EventLoopFuture<Bool>{
    return context.collection(for: User.self).findOne(where: "isSystemAdmin" == true)
    //return context.findOne(User.self,where: Query.valEquals(field: "isSystemAdmin", val: true))
        .flatMap({ user  in
            if let _ = user {
                return context.eventLoop.makeSucceededFuture( false)
            }else {
                //create Admin user
                return createUser(name: "Admin", email: config.initialAdminEmail, password: config.initialAdminPassword, isSystemAdmin:true, isActivated: true, into: context)
                    .map{_ in  true}
            }
        })
}

func createUser(name:String,email:String,password:String,isSystemAdmin:Bool = false, isActivated:Bool = false , into context:Meow.MeowDatabase) -> EventLoopFuture<User>{
    //find existing user
    return findUser(by: email, into: context).flatMap { user in
        guard user == nil else { return context.eventLoop.makeFailedFuture(UserError.alreadyExist)}
        //{ throw UserError.alreadyExist }
        
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
        return createdUser.save(in: context).map{ _ in createdUser}
    }
}

func updateUser(user:User, newName:String?,newPassword:String?, newFavoritesApplicationsUUID:[String]? ,isSystemAdmin:Bool?,isActivated:Bool?, into context:Meow.MeowDatabase) throws -> EventLoopFuture<User>{
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
    return user.save(in: context).map{_ in user}
}

func disableUser(user:User,into context:Meow.MeowDatabase) -> EventLoopFuture<User>{
    user.isActivated = false
    //generate activation token
    user.activationToken = UUID().uuidString
    return user.save(in: context).map{_ in user}
}

func activateUser(withToken:String, into context:Meow.MeowDatabase) -> EventLoopFuture<User>{
    return findActivableUser(by: withToken, into: context)
        .flatMap({ user in
            guard let user = user else { return context.eventLoop.makeFailedFuture(UserError.notFound)}
            //{ throw UserError.notFound }
            //activate user
            user.isActivated = true
            user.activationToken  = nil
            return user.save(in: context).map{_ in user}
        })
}

func deleteUser(withEmail email:String, into context:Meow.MeowDatabase) throws -> EventLoopFuture<Void>{
    return context.collection(for: User.self).deleteOne(where: "email" == email)
   // return context.deleteOne(User.self, where: Query.valEquals(field: "email", val: email))
        .flatMapThrowing({ deleteReply -> () in
            guard deleteReply.deletes == 1 else { throw UserError.notFound }
        })
}

func delete(user:User, into context:Meow.MeowDatabase) -> EventLoopFuture<Void>{
    return context.collection(for: User.self).deleteOne(where: "_id" == user._id)
        .map{ _ in return }
    //return context.delete(user)
}

func resetUser(user:User,newPassword:String,into context:Meow.MeowDatabase) -> EventLoopFuture<User>{
    user.password = generateHashedPassword(plain: newPassword,salt: user.salt)
    //generate activation token
    user.activationToken = UUID().uuidString
    user.isActivated = false
    return user.save(in: context).map{_ in user}
}

private func checkPassword(plain:String,salt:String,hash:String) -> Bool{
    return generateHashedPassword(plain: plain, salt: salt) == hash
}

private func generateSalt() -> String {
    return UUID().uuidString
}

func generateHashedPassword(plain:String,salt:String) -> String {
    return "\(plain):\(salt)".md5()
}
