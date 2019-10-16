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
                            })
                    })
            })
        // throw Abort(.custom(code: 500, reasonPhrase: "Not Implemented"))
    }
    
    func login(_ req: Request) throws -> Future<LoginRespDto> {
        return try req.content.decode(LoginReqDto.self)
            .flatMap{ loginDto -> Future<LoginRespDto>  in
                let context = try req.context()
                return try findUser(by: loginDto.email, and: loginDto.password, updateLastLogin: true, into: context)
                    .flatMap({ user in
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
                    })
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
        .flatMap({_ in
        let context = try req.context()
        
        let result:MappedCursor<MappedCursor<FindCursor, User>, UserDto> = try allUsers(into: context)
            .map(transform: {UserDto.create(from: $0, content: .full)})
       // .getAllResults()
            
        //    Future<Paginated<UserDto>> = try allUsers(into: context)
           // .map(transform: {user -> UserDto in
             //   return UserDto.create(from: user, content: .full)})
          //  .paginate(for: req)
        //:MappedCursor<FindCursor, UserDto>
            let test:Future<Paginated<UserDto>> = result.paginate(for: req, sortFields: ["email" : "email"])
        return test

        /*
         MappedCursor<MappedCursor<FindCursor, User>, UserDto>
        return try retrieveMandatoryAdminUser(from: req)
            .flatMap({ adminUser in
                let context = try req.context()
                return try allUsers(into: context).underlyingCursor
            })
 */
        })
    }
    
    func update(_ req: Request) throws -> Future<UserDto> {
        return try retrieveMandatoryUser(from: req)
        .flatMap({user throws -> Future<UserDto> in
            return try req.content.decode(UpdateUserDto.self)
            .flatMap({ updateDto  in
                //update user
                let context = try req.context()
                return try updateUser(user: user, newName: updateDto.name, newPassword: updateDto.password, newFavoritesApplicationsUUID: updateDto.favoritesApplicationsUUID, into: context)
                    .map{UserDto.create(from: $0, content: .full)}
            })
        })
    }
    
    func activation(_ req: Request) throws -> Future<MessageDto> {
        if let activationToken = try? req.query.get(String.self, at: "activationToken") {
            //activate user
            let context = try req.context()
            return try activateUser(withToken: activationToken, into: context)
                .map { MessageDto(message:"Activation Done")}
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

