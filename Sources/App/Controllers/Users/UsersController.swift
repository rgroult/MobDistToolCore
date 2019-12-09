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
import Pagination
import zxcvbn

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
    
    let sortFields = ["email" : "email","created" : "createdAt","lastlogin" : "lastLogin"]
    
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
                //check password strength
                let strength = Zxcvbn.estimateScore(registerDto.password)
                guard strength >= config.minimumPasswordStrength else { throw UserError.invalidPassworsStrength(required: config.minimumPasswordStrength)}
                
                //register user
                let needRegistrationEmail = !config.automaticRegistration
                let context = try req.context()
                
                return try createUser(name: registerDto.name, email: registerDto.email, password: registerDto.password, isActivated:!needRegistrationEmail, into: context)
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
                .do({[weak self]  dto in self?.track(event: .Register(email: registerDto.email, isSuccess: true), for: req)})
                .catch({[weak self]  error in self?.track(event: .Register(email: registerDto.email, isSuccess: false,failedError:error), for: req)})
        }
    }
    
    func forgotPassword(_ req: Request) throws -> Future<MessageDto> {
        return try req.content.decode(ForgotPasswordDto.self)
            .flatMap({ forgotPasswordDto in
                let config = try req.make(MdtConfiguration.self)
                if config.automaticRegistration {
                    //ask to a admin
                    throw  Abort(.badRequest, reason: "Contact an administrator to retrieve new password")
                }
                //reset user
                let context = try req.context()
                let newPassword = random(15)
                return try findUser(by: forgotPasswordDto.email, into: context)
                    .flatMap({ user  in
                        guard let user = user else { throw UserError.notFound}
                        return try resetUser(user: user, newPassword: newPassword, into: context)
                            .flatMap({ user in
                                let message = MessageDto(message:"Your account has been temporarily desactivated, a email with new password and activation link was sent")
                                //sent reset email
                                let emailService = try req.make(EmailService.self)
                                return try emailService.sendResetEmail(for: user, newPassword: newPassword, into: req)
                                    .map { message}
                                    .do({ [weak self] dto in self?.track(event: .ForgotPassword(email: user.email), for: req)})
                            })
                    })
            })
        // throw Abort(.custom(code: 500, reasonPhrase: "Not Implemented"))
    }
    func login(_ req: Request) throws -> Future<LoginRespDto> {
        let config = try req.make(MdtConfiguration.self)
        let delay = config.loginResponseDelay
        //return try self.loginDelayed(req)
        return req.eventLoop.scheduleTask(in: TimeAmount.seconds(delay)) { return try self.loginDelayed(req)}
            .futureResult.flatMap{$0}
    }
    
    func loginDelayed(_ req: Request) throws -> Future<LoginRespDto> {
        return try req.content.decode(LoginReqDto.self)
            .flatMap{ loginDto -> Future<LoginRespDto>  in
                let context = try req.context()
                return try findUser(by: loginDto.email, and: loginDto.password, updateLastLogin: true, into: context)
                .map({ user in
                    // user is activated ?
                    guard user.isActivated else { throw UserError.notActivated}
                    let signers = try req.make(JWTSigners.self)
                   // let signer = try signers.requireSigner(kid:signerIdentifier)
                    let signer = JWTSigner.hs256(key: Data("secret".utf8))
                    let jwt = JWT(header: JWTHeader(kid: signerIdentifier), payload: JWTTokenPayload(email: user.email))
                    let signatureData = try jwt.sign(using: signer)
                    let token = String(bytes: signatureData, encoding: .utf8)!
                    return LoginRespDto( email: user.email, name: user.name,token:token)
                })
                    /*.flatMap({ user in
                        // user is activated ?
                        guard user.isActivated else { throw UserError.notActivated}
                        //generate token in header
                        let signers = try req.make(JWTSigners.self)
                        return try signers.get(kid: signerIdentifier, on: req)
                            .map{ signer in
                                let jwt = JWT(header: .init(kid: signerIdentifier), payload: JWTTokenPayload(email: user.email))
                                let signatureData = try jwt.sign(using: signer)
                                let token = String(bytes: signatureData, encoding: .utf8)!
                                return LoginRespDto( email: user.email, name: user.name,token:token)
                        }
                    })*/
                    .do({[weak self]  dto in self?.track(event: .Login(email: dto.email, isSuccess: true), for: req)})
                    .catch({[weak self]  error in self?.track(event: .Login(email: loginDto.email, isSuccess: false,failedError:error), for: req)})
        }
    }
    
    func me(_ req: Request) throws -> Future<UserDto> {
        return try retrieveMandatoryUser(from: req)
            .flatMap({user throws -> Future<UserDto> in
                let context = try req.context()
                //administreted Applications
                return try findApplications(for: user, into: context)
                    .map(transform: {ApplicationSummaryDto(from: $0)})
                    .getAllResults()
                    .map{apps -> UserDto in
                        var userDto = UserDto.create(from: user, content: .full)
                        userDto.administeredApplications = apps
                        return userDto
                }
            })
    }
    
    func all(_ req: Request) throws -> Future<Paginated<UserDto>> {
        return try retrieveMandatoryAdminUser(from: req)
            .flatMap({[weak self]_ in
                guard let `self` = self else { throw Abort(.internalServerError)}
                let context = try req.context()
                
                let searchQuery = try self.extractSearch(from: req, searchField: "email")
                
                let cursor:MappedCursor<MappedCursor<FindCursor, User>, UserDto> = try allUsers(into: context, additionalQuery:searchQuery )
                    .map(transform: {UserDto.create(from: $0, content: .full)})
                
                let result:Future<Paginated<UserDto>> = cursor.paginate(for: req, sortFields: self.sortFields,defaultSort: "email", findQuery: searchQuery)
                return result
            })
    }
    
    func update(_ req: Request) throws -> Future<UserDto> {
        return try retrieveMandatoryUser(from: req)
            .flatMap({user throws -> Future<UserDto> in
                return try req.content.decode(UpdateUserDto.self)
                    .flatMap({ updateDto  in
                        //update user
                        let context = try req.context()
                        return try App.updateUser(user: user, newName: updateDto.name, newPassword: updateDto.password, newFavoritesApplicationsUUID: updateDto.favoritesApplicationsUUID,isSystemAdmin: nil,isActivated: nil, into: context)
                            .map{UserDto.create(from: $0, content: .full)}
                    })
                    .do({[weak self]  dto in self?.track(event: .UpdateUser(email: user.email, isSuccess: true), for: req)})
                    .catch({[weak self]  error in self?.track(event: .UpdateUser(email: user.email, isSuccess: false,failedError:error), for: req)})
            })
    }
    
    func updateUser(_ req: Request) throws -> Future<UserDto> {
        let email = try req.parameters.next(String.self)
        return try retrieveMandatoryAdminUser(from: req)
            .flatMap({ _ throws -> Future<UserDto> in
                return try req.content.decode(UpdateUserFullDto.self)
                    .flatMap({ updateDto  in
                        let context = try req.context()
                        //find user
                        return try findUser(by: email, into: context)
                            .flatMap { user  in
                                guard let user = user else { throw Abort(.notFound)}
                                return try App.updateUser(user: user, newName: updateDto.name, newPassword: updateDto.password, newFavoritesApplicationsUUID: updateDto.favoritesApplicationsUUID, isSystemAdmin: updateDto.isSystemAdmin, isActivated: updateDto.isActivated, into: context)
                                    .map{UserDto.create(from: $0, content: .full)}
                        }
                    })
            })
            .do({[weak self]  dto in self?.track(event: .UpdateUser(email: email, isSuccess: true), for: req)})
            .catch({[weak self]  error in self?.track(event: .UpdateUser(email: email, isSuccess: false,failedError:error), for: req)})
    }
    
    func deleteUser(_ req: Request) throws -> Future<MessageDto> {
        let email = try req.parameters.next(String.self)
        return try retrieveMandatoryAdminUser(from: req)
            .flatMap({ _ throws in
                let context = try req.context()
                //find user
                return try findUser(by: email, into: context)
                    .flatMap { user  in
                        guard let user = user else { throw Abort(.notFound)}
                        return try delete(user: user, into: context).map {
                            return MessageDto(message: "User Deleted")
                        }
                        
                }
            })
            .do({ [weak self] dto in self?.track(event: .DeleteUser(email: email, isSuccess:true), for: req)})
            .catch({[weak self]  error in self?.track(event: .DeleteUser(email: email, isSuccess: false,failedError:error), for: req)})
    }
    
    func activation(_ req: Request) throws -> Future<MessageDto> {
        if let activationToken = try? req.query.get(String.self, at: "activationToken") {
            //activate user
            let context = try req.context()
            return try activateUser(withToken: activationToken, into: context)
                .do({[weak self]  user in self?.track(event: .Activation(email: user.email, isSuccess: true), for: req)})
                .catch({[weak self]  error in self?.track(event: .Activation(email: "<Token>", isSuccess: false,failedError:error), for: req)})
                .map { _ in MessageDto(message:"Activation Done")}
                .thenIfErrorThrowing({ error in
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

