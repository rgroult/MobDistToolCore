//
//  UsersController+OpenAPIBuilder.swift
//  App
//
//  Created by Rémi Groult on 14/02/2019.
//

import Foundation
import Swiftgger
import Meow
import Pagination

extension UsersController:APIBuilderControllerProtocol {
    func generateOpenAPI(apiBuilder:OpenAPIBuilder){
        //add api controller
        _ = apiBuilder.add(
            APIController(name: pathPrefix,
                          description: "Controller for users",
                          actions: [
                            APIAction(method: .post, route: generateRoute(Verb.register.rawValue),
                                      summary: "Register",
                                      description: "Action for getting specific user from server",
                                      request: APIRequest(object: RegisterDto.self, description: "Register user information."),
                                      responses: [
                                        APIResponse(code: "200", description: "User created", object: UserDto.self),
                                        APIResponse(code: "500", description: "Registration error")
                                ],
                                      authorization: false
                            ),
                            APIAction(method: .post, route: generateRoute(Verb.forgotPassword.rawValue),
                                      summary: "Forgot Password",
                                      description: "Send re activation email with new password if self registration, otherwise throw error",
                                      request: APIRequest(object: ForgotPasswordDto.self, description: "User email."),
                                      responses: [
                                        APIResponse(code: "200", description: "Password reseted", object: MessageDto.self),
                                        APIResponse(code: "500", description: "Registration error"),
                                        APIResponse(code: "400", description: "Contact an administrator to retrieve new password")
                                ],
                                      authorization: false
                            ),
                            APIAction(method: .post, route: generateRoute(Verb.login.rawValue),
                                      summary: "Login",
                                      description: "Login and retrieve JWT token",
                                      request: APIRequest(object: LoginReqDto.self, description: "Login info."),
                                      responses: [
                                        APIResponse(code: "200", description: "Password reseted", object: LoginRespDto.self),
                                        APIResponse(code: "500", description: "Registration error"),
                                        APIResponse(code: "400", description: "Contact an administrator to retrieve new password")
                                ],
                                      authorization: false
                            ),
                            APIAction(method: .post, route: generateRoute(Verb.refresh.rawValue),
                                      summary: "Refresh Login",
                                      description: "Refresh login with refresh token and retrieve JWT token",
                                      request: APIRequest(object: RefreshTokenDto.self, description: "Refresh info."),
                                      responses: [
                                        APIResponse(code: "200", description: "Password reseted", object: LoginRespDto.self),
                                        APIResponse(code: "500", description: "Registration error"),
                                        APIResponse(code: "400", description: "Contact an administrator to retrieve new password")
                                ],
                                      authorization: false
                            ),
                            APIAction(method: .get, route: generateRoute(Verb.me.rawValue),
                                      summary: "Me",
                                      description: "Retrieve Profile",
                                      responses: [
                                        APIResponse(code: "200", description: "My profile", object: UserDto.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "401", description: "Authentication error Error"),
                                ],
                                      authorization: true
                            ),
                            APIAction(method: .get, route: generateRoute(""),
                                      summary: "All USers",
                                      description: "Retrieve users Profile : need be admin",
                                      parameters: generatePaginationParameters(sortby: Array(sortFields.keys), searchByField: "email"),
                                      responses: [
                                        APIResponse(code: "200", description: "Profiles found", object: Paginated<UserDto>.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "401", description: "Authentication error Error"),
                                ],
                                      authorization: true
                            ),
                            APIAction(method: .put, route: generateRoute(Verb.specificUser.rawValue),
                                      summary: "Update User",
                                      description: "Update user Profile : need be admin",
                                      parameters: [ APIParameter(name: "email", parameterLocation:.path, description: "Email", required: true)],
                                      request: APIRequest(object: UpdateUserFullDto.self, description: "Update info."),
                                      responses: [
                                        APIResponse(code: "200", description: "Profiles found", object: Paginated<UserDto>.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "401", description: "Authentication error Error"),
                                ],
                                      authorization: true
                            ),
                            APIAction(method: .delete, route: generateRoute(Verb.specificUser.rawValue),
                                      summary: "Delete User",
                                      description: "Delete user : need be admin",
                                      parameters: [ APIParameter(name: "email", parameterLocation:.path, description: "Email", required: true)],
                                      responses: [
                                        APIResponse(code: "200", description: "Profiles found", object: Paginated<MessageDto>.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "401", description: "Authentication error Error"),
                                ],
                                      authorization: true
                            ),
                            APIAction(method: .put, route: generateRoute(Verb.me.rawValue),
                                      summary: "Update",
                                      description: "Update Profile",
                                       request: APIRequest(object: UpdateUserDto.self, description: "Update info."),
                                      responses: [
                                        APIResponse(code: "200", description: "My profile", object: UserDto.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "401", description: "Authentication error Error"),
                                ],
                                      authorization: true
                            ),
                            APIAction(method: .get, route: generateRoute(Verb.activation.rawValue),
                                      summary: "Activation",
                                      description: "Activate User",
                                      parameters: [APIParameter(name: "activationToken", parameterLocation:.query, description: "Activation token", required: true)],
                                      responses: [
                                        APIResponse(code: "200", description: "Sucess", object: MessageDto.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "400", description: "Request error"),
                                        ],
                                      authorization: true
                            )
                ]
            )
        )
        _ = apiBuilder.add([APIObject(object: LoginReqDto( email: "email@test.com", password: "1234")),APIObject(object: LoginRespDto(email:"john@doe.com",name:"John Doe",token:"554dsr45f8sdf5",refreshToken: "1223434")), APIObject(object: RefreshTokenDto(email: "john@doe.com", refreshToken: "ZEAZRS124325EFS"))])
        _ = apiBuilder.add([APIObject(object: UserDto.sample()),APIObject(object: UpdateUserDto.sample()),APIObject(object: MessageDto.sample()),APIObject(object: UpdateUserFullDto.sample())])
        _ = apiBuilder.add([APIObject(object: RegisterDto( email: "email@test.com", name: "John Doe", password: "password"))])
        _ = apiBuilder.add([APIObject(object: ForgotPasswordDto( email: "email@test.com"))])
        _ = apiBuilder.add([APIObject(object: Paginated.sample(obj: UserDto.sample()))])
        _ = apiBuilder.add([APIObject(object: Paginated.sample(obj: MessageDto.sample()))])
    }
}

