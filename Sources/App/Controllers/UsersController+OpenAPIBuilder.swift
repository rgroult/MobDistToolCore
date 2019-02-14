//
//  UsersController+OpenAPIBuilder.swift
//  App
//
//  Created by Rémi Groult on 14/02/2019.
//

import Foundation
import Swiftgger

extension UsersController {
    func generateOpenAPI(apiBuilder:OpenAPIBuilder){
        //add api controller
        _ = apiBuilder.add(
            APIController(name: "Users",
                          description: "Controller for users",
                          actions: [
                            APIAction(method: .post, route: generateRoute("register"),
                                      summary: "Register",
                                      description: "Action for getting specific user from server",
                                      request: APIRequest(object: RegisterDto.self, description: "Register user information."),
                                      responses: [
                                        APIResponse(code: "200", description: "User created", object: UserDto.self),
                                        APIResponse(code: "500", description: "Registration error")
                                ],
                                      authorization: false
                            ),
                            APIAction(method: .post, route: generateRoute("forgotPassword"),
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
                            APIAction(method: .post, route: generateRoute("login"),
                                      summary: "Login",
                                      description: "Login and retrieve JWT token",
                                      request: APIRequest(object: LoginDto.self, description: "Login info."),
                                      responses: [
                                        APIResponse(code: "200", description: "Password reseted", object: MessageDto.self),
                                        APIResponse(code: "500", description: "Registration error"),
                                        APIResponse(code: "400", description: "Contact an administrator to retrieve new password")
                                ],
                                      authorization: false
                            )
                ]
            )
        )
        _ = apiBuilder.add([APIObject(object: UserDto( email: "email@test.com", name: "John Doe", isActivated: false))])
        _ = apiBuilder.add([APIObject(object: RegisterDto( email: "email@test.com", name: "John Doe", password: "password"))])
        _ = apiBuilder.add([APIObject(object: MessageDto( message: "message"))])
        _ = apiBuilder.add([APIObject(object: ForgotPasswordDto( email: "email@test.com"))])
    }
}
