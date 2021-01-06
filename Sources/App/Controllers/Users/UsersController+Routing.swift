//
//  UsersController+Routing.swift
//  App
//
//  Created by Rémi Groult on 20/02/2019.
//

import Vapor

extension UsersController {
    
    enum Verb:String {
        case login, refresh, me, activation,register, forgotPassword
        case specificUser = "{email}"
    }
    
    func configure(with router: RoutesBuilder, and protectedRouter:RoutesBuilder){
        let usersRouter = router.grouped("\(controllerVersion)/\(pathPrefix)")
        usersRouter.post([.constant(Verb.login.rawValue)], use: self.login)
        usersRouter.post([.constant(Verb.refresh.rawValue)], use: self.refreshLogin)
        usersRouter.post([.constant(Verb.register.rawValue)], use: self.register)
        usersRouter.post([.constant(Verb.forgotPassword.rawValue)], use: self.forgotPassword)
        usersRouter.get([.constant(Verb.activation.rawValue)], use: self.activation)
        
        let usersProtectedRouter = protectedRouter.grouped("\(controllerVersion)/\(pathPrefix)")
        usersProtectedRouter.get([.constant(Verb.me.rawValue)], use: self.me)
        usersProtectedRouter.put([.constant(Verb.me.rawValue)], use: self.update)
        usersProtectedRouter.get([], use: self.all)
        usersProtectedRouter.put([.parameter("email")], use: self.updateUser)
        usersProtectedRouter.delete([.parameter("email")], use: self.deleteUser)
    }
}
