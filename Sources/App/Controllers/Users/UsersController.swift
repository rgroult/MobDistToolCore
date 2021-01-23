//
//  UsersController.swift
//  App
//
//  Created by Rémi Groult on 12/02/2019.
//

import Vapor
import Meow
import BSON
import Swiftgger
import JWT
import JWTAuth
import SwiftSMTP
//import Pagination
import zxcvbn

enum RegistrationError : Error {
    case invalidEmailFormat, emailDomainForbidden
}

extension RegistrationError:DebuggableError {
    var reason: String {
        switch self {
        case .invalidEmailFormat:
            return "RegistrationError.invalidEmailFormat"
        case .emailDomainForbidden:
            return "RegistrationError.emailDomainForbidden"
        }
    }
    
    var identifier: String {
        return "RegistrationError"
    }
}

final class UsersController:BaseController {
    weak var appController:ApplicationsController?
    
    /*  override var  controllerVersion = "v2"
     var pathPrefix = "Users"
     */
    init(apiBuilder:OpenAPIBuilder) {
        super.init(version: "v2", pathPrefix: "Users", apiBuilder: apiBuilder)
    }
    
    let sortFields = ["email" : "email","created" : "createdAt","lastlogin" : "lastLogin"]
    
    func register(_ req: Request) throws -> EventLoopFuture<UserDto> {
        let config = try req.application.appConfiguration()    //req.make(MdtConfiguration.self)
        let registerDto =  try req.content.decode(RegisterDto.self)
            //.flatMap{ registerDto -> EventLoopFuture<UserDto>  in
                
                guard registerDto.email.isValidEmail() else { throw RegistrationError.invalidEmailFormat}
                
                //check in white domains
                if let whiteDomains = config.registrationWhiteDomains, !whiteDomains.isEmpty {
                    if whiteDomains.firstIndex(where: {registerDto.email.hasSuffix($0)}) == nil {
                        throw RegistrationError.emailDomainForbidden
                    }
                }
                //check password strength
                let strength = Zxcvbn.estimateScore(registerDto.password)
                guard strength >= config.minimumPasswordStrength else { throw UserError.invalidPassworsStrength(required: config.minimumPasswordStrength)}
                
                //register user
                let needRegistrationEmail = !config.automaticRegistration
                let meow = req.meow
                
                return createUser(name: registerDto.name, email: registerDto.email, password: registerDto.password, isActivated:!needRegistrationEmail, into: meow)
                    .flatMap{ user in
                        let userCreated = UserDto.create(from: user, content: ModelVisibility.full)
                        if needRegistrationEmail {
                            do {
                            //sent registration email
                            let emailService = try req.application.appEmailService()
                            return emailService.sendValidationEmail(for: user, into: req.eventLoop).map{
                                userCreated }
                                .flatMapError({ error -> EventLoopFuture<UserDto> in
                                    //delete create user
                                    return delete(user: user, into: meow).flatMapThrowing{
                                        throw error
                                    }
                                })
                            }catch {
                                //delete create user
                                return delete(user: user, into: meow).flatMapThrowing{
                                    throw error
                                }
                            }
                        }else {
                            return req.eventLoop.makeSucceededFuture(userCreated)
                        }
                }
                .do({[weak self]  dto in self?.track(event: .Register(email: registerDto.email, isSuccess: true), for: req)})
                .catch({[weak self]  error in
                        self?.track(event: .Register(email: registerDto.email, isSuccess: false,failedError:error), for: req)})
    }
    
    func forgotPassword(_ req: Request) throws -> EventLoopFuture<MessageDto> {
        let forgotPasswordDto =  try req.content.decode(ForgotPasswordDto.self)
            //.flatMap({ forgotPasswordDto in
        let config = try req.application.appConfiguration()//  req.make(MdtConfiguration.self)
                if config.automaticRegistration {
                    //ask to a admin
                    throw  Abort(.badRequest, reason: "Contact an administrator to retrieve new password")
                }
                //reset user
        let meow = req.meow
        let emailService = try req.application.appEmailService()
                let newPassword = random(15)
                return findUser(by: forgotPasswordDto.email, into: meow)
                    .flatMapThrowing({ user in
                        guard let user = user else { throw UserError.notFound}
                        return user
                    })
                    .flatMap({ user  in
                        return resetUser(user: user, newPassword: newPassword, into: meow)
                            .flatMap({ user in
                                let message = MessageDto(message:"Your account has been temporarily desactivated, a email with new password and activation link was sent")
                                //sent reset email
                                let sendEmailFuture:EventLoopFuture<Void>
                                do {
                                    sendEmailFuture = try emailService.sendResetEmail(for: user, newPassword: newPassword, into: req.eventLoop)
                                }catch {
                                    return req.eventLoop.makeFailedFuture(error)
                                }
                                return sendEmailFuture
                                    .map { message}
                                    .do({ [weak self] dto in self?.track(event: .ForgotPassword(email: user.email), for: req)})
                            })
                    })
        //    })
        // throw Abort(.custom(code: 500, reasonPhrase: "Not Implemented"))
    }
    
    func refreshLogin(_ req: Request) throws -> EventLoopFuture<LoginRespDto> {
        let refreshDto = try req.content.decode(RefreshTokenDto.self)
          //  .flatMap{ refreshDto -> Future<LoginRespDto>  in
                //let signers = try req.make(MDT_Signers.self)
                //let signer = signers.signer()
                //verify refreshToken
        //let payload = try req.jwt.verify(as: TestPayload.self)
        let token:JWTRefreshTokenPayload
              //  let token:JWT<JWTRefreshTokenPayload>
                do {
                    token = try req.jwt.verify(refreshDto.refreshToken, as: JWTRefreshTokenPayload.self)
                        //try JWT<JWTRefreshTokenPayload>(from: refreshDto.refreshToken, verifiedUsing: signer)
                }catch {
                    throw Abort(.unauthorized, reason: "Invalid credentials")
                }
                guard token.username == refreshDto.email else { throw Abort(.unauthorized, reason: "Invalid credentials") }
        let meow = req.meow
                return findUser(by: refreshDto.email, into: meow)
                    .flatMapThrowing { user in
                        guard let user = user else { throw UserError.notFound }
                        return try UsersController.generateDto(req, user: user, generateRefeshToken: false)
                }
                .do({[weak self]  dto in self?.track(event: .RefreshLogin(email: dto.email, isSuccess: true), for: req)})
                .catch({[weak self]  error in self?.track(event: .RefreshLogin(email: refreshDto.email, isSuccess: false,failedError:error), for: req)})
       // }
    }
    
    func login(_ req: Request) throws -> EventLoopFuture<LoginRespDto> {
        let config = try req.application.appConfiguration()
        let delay = config.loginResponseDelay
        return req.eventLoop.scheduleTask(in: TimeAmount.seconds(Int64(delay))) { return try self.loginDelayed(req)}
            .futureResult.flatMap{$0}
    }
    
    func loginDelayed(_ req: Request) throws -> EventLoopFuture<LoginRespDto> {
        let loginDto =  try req.content.decode(LoginReqDto.self)
          //  .flatMap{ loginDto -> EventLoopFuture<LoginRespDto>  in
                let meow = req.meow
                return findUser(by: loginDto.email, and: loginDto.password, updateLastLogin: true, into: meow)
                    .flatMapThrowing({ user in
                        return try UsersController.generateDto(req, user: user, generateRefeshToken: true)
                    })
                    .do({[weak self]  dto in self?.track(event: .Login(email: dto.email, isSuccess: true), for: req)})
                    .catch({[weak self]  error in self?.track(event: .Login(email: loginDto.email, isSuccess: false,failedError:error), for: req)})
      //  }
    }
    
    
    class func generateDto(_ req: Request,user:User,generateRefeshToken:Bool)throws -> LoginRespDto{
        // user is activated ?
        guard user.isActivated else { throw UserError.notActivated}
     /*   let signers = try req.make(MDT_Signers.self)
        let signer = signers.signer()
        let jwt = JWT(header: JWTHeader(kid: signerIdentifier), payload: JWTTokenPayload(email: user.email))
        let token = String(bytes: try jwt.sign(using: signer), encoding: .utf8)!*/
        let token = try req.jwt.sign(JWTTokenPayload(email: user.email))
        var refreshToken:String? = nil
        if generateRefeshToken {
           // let jwt = JWT(header: JWTHeader(kid: signerIdentifier), payload: JWTRefreshTokenPayload(email: user.email))
            refreshToken = try req.jwt.sign(JWTRefreshTokenPayload(email: user.email))
            //refreshToken = String(bytes: try jwt.sign(using: signer), encoding: .utf8)!
        }
        
        return LoginRespDto( email: user.email, name: user.name,token:token,refreshToken: refreshToken)
    }
    
    func me(_ req: Request) throws -> EventLoopFuture<UserDto> {
        let meow = req.meow
        guard let appController = appController else { throw Abort(.internalServerError)}
        return try retrieveMandatoryUser(from: req)
            .flatMap({user -> EventLoopFuture<UserDto> in
                //administreted Applications
                return findApplications(for: user, into: meow)
                    .map(transform: {appController.generateSummaryDto(from: $0)})
                    // .map(transform: {ApplicationSummaryDto(from: $0)})
                    .allResults()
                    .map{apps -> UserDto in
                        var userDto = UserDto.create(from: user, content: .full)
                        userDto.administeredApplications = apps
                        return userDto
                }
            })
    }
    
    func all(_ req: Request) throws -> EventLoopFuture<Paginated<UserDto>> {
        let searchQuery = try self.extractSearch(from: req, searchField: "email")
        return try retrieveMandatoryAdminUser(from: req)
            .flatMap({_ -> EventLoopFuture<Paginated<UserDto>> in
               // guard let `self` = self else { throw Abort(.internalServerError)}
                let meow = req.meow
             /*   let cursor:MappedCursor<MappedCursor<FindQueryBuilder, User>,UserDto> = allUsers(into: meow, additionalQuery:searchQuery )
                   .map{result -> UserDto in return UserDto.create(from: result, content: .full)}
                
                let result:EventLoopFuture<Paginated<UserDto>> = cursor.paginate(for: req, model: User.self, sortFields: self.sortFields,defaultSort: "email", findQuery: searchQuery)
 
                */
                let findQuery = allUsers(into: meow, additionalQuery: searchQuery)
                
                return findQuery.paginate(for: req, model: User.self, sortFields: self.sortFields, defaultSort: "email", findQuery: searchQuery, transform: {UserDto.create(from: $0, content: .full)})
                
                //return result
            })
    }
    
    func update(_ req: Request) throws -> EventLoopFuture<UserDto> {
        let updateDto = try req.content.decode(UpdateUserDto.self)
        let config = try req.application.appConfiguration()
        return try retrieveMandatoryUser(from: req)
            .flatMap({user -> EventLoopFuture<UserDto> in
                        //update user
                        let meow = req.meow
                let updateUserFuture:EventLoopFuture<User>
                do {
                        if let password = updateDto.password {
                            //check password strength
                            let strength = Zxcvbn.estimateScore(password)
                            guard strength >= config.minimumPasswordStrength else { throw UserError.invalidPassworsStrength(required: config.minimumPasswordStrength)}

                            //check if current password is correct if user is not Admin
                            if !user.isSystemAdmin {
                                guard let currentPassword = updateDto.currentPassword else { throw UserError.invalidLoginOrPassword }
                                let passwordHash = generateHashedPassword(plain: currentPassword,salt: user.salt)
                                guard passwordHash == user.password else { throw UserError.invalidLoginOrPassword }
                            }
                        }
                    updateUserFuture = try App.updateUser(user: user, newName: updateDto.name, newPassword: updateDto.password, newFavoritesApplicationsUUID: updateDto.favoritesApplicationsUUID,isSystemAdmin: nil,isActivated: nil, into: meow)
                }catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
                        return updateUserFuture
                            .map{UserDto.create(from: $0, content: .full)}
                            //Add administrated App
                            .flatMap({[weak self] userDto in
                                guard let appController = self?.appController else { return req.eventLoop.makeFailedFuture (Abort(.internalServerError))}
                                //administreted Applications
                                return findApplications(for: user, into: meow)
                                    .map(transform: {appController.generateSummaryDto(from: $0)})
                                    // .map(transform: {ApplicationSummaryDto(from: $0)})
                                    .allResults()
                                    .map{apps -> UserDto in
                                        var result = userDto
                                        result.administeredApplications = apps
                                        return result
                                }
                            })
                    .do({[weak self]  dto in self?.track(event: .UpdateUser(email: user.email, isSuccess: true), for: req)})
                    .catch({[weak self]  error in self?.track(event: .UpdateUser(email: user.email, isSuccess: false,failedError:error), for: req)})
            })
    }
    
    func updateUser(_ req: Request) throws -> EventLoopFuture<UserDto> {
        guard let email = req.parameters.get("email") else { throw Abort(.badRequest)}
        let updateDto = try req.content.decode(UpdateUserFullDto.self)
        return try retrieveMandatoryAdminUser(from: req)
            .flatMap({ _ -> EventLoopFuture<UserDto> in
               // return try req.content.decode(UpdateUserFullDto.self)
                   // .flatMap({ updateDto  in
                        let meow = req.meow
                        //find user
                        return findUser(by: email, into: meow)
                            .flatMap { user  in
                                do {
                                guard let user = user else { throw Abort(.notFound)}
                                return try App.updateUser(user: user, newName: updateDto.name, newPassword: updateDto.password, newFavoritesApplicationsUUID: updateDto.favoritesApplicationsUUID, isSystemAdmin: updateDto.isSystemAdmin, isActivated: updateDto.isActivated, into: meow)
                                    .map{UserDto.create(from: $0, content: .full)}
                                }catch {
                                    return req.eventLoop.makeFailedFuture( error)
                                }
                        }
                 //   })
            })
            .do({[weak self]  dto in self?.track(event: .UpdateUser(email: email, isSuccess: true), for: req)})
            .catch({[weak self]  error in self?.track(event: .UpdateUser(email: email, isSuccess: false,failedError:error), for: req)})
    }
    
    func deleteUser(_ req: Request) throws -> EventLoopFuture<MessageDto> {
        guard let email = req.parameters.get("email") else { throw Abort(.badRequest)}
        return try retrieveMandatoryAdminUser(from: req)
            .flatMap({ _ in
                let meow = req.meow
                //find user
                return findUser(by: email, into: meow)
                    .flatMap { user  in
                        guard let user = user else { return req.eventLoop.makeFailedFuture( Abort(.notFound))}
                        return delete(user: user, into: meow).map {
                            return MessageDto(message: "User Deleted")
                        }
                }
            })
            .do({ [weak self] dto in self?.track(event: .DeleteUser(email: email, isSuccess:true), for: req)})
            .catch({[weak self]  error in self?.track(event: .DeleteUser(email: email, isSuccess: false,failedError:error), for: req)})
    }
    
    func activation(_ req: Request) throws -> EventLoopFuture<MessageDto> {
        if let activationToken = try? req.query.get(String.self, at: "activationToken") {
            //activate user
            let meow = req.meow
            return activateUser(withToken: activationToken, into: meow)
                .do({[weak self]  user in self?.track(event: .Activation(email: user.email, isSuccess: true), for: req)})
                .catch({[weak self]  error in self?.track(event: .Activation(email: "<Token>", isSuccess: false,failedError:error), for: req)})
                .map { _ in MessageDto(message:"Activation Done")}
                .flatMapErrorThrowing({ error in
                    if let userError = error as? UserError, userError == UserError.notFound {
                        throw Abort(.badRequest, reason: "Invalid activationToken")
                    }
                    throw error
                })
        }else {
            throw Abort(.badRequest, reason: "Invalid activationToken")
        }
    }
}

