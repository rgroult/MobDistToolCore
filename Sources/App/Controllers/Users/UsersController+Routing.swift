//
//  UsersController+Routing.swift
//  App
//
//  Created by Rémi Groult on 20/02/2019.
//

import Vapor

extension UsersController {
    
    enum Verb:String {
        case login, me, activation,register, forgotPassword
        case specificUser = "{email}"
    }
    
    func configure(with router: Router, and protectedRouter:Router){
        let usersRouter = router.grouped("\(controllerVersion)/\(pathPrefix)")
        usersRouter.post(Verb.login.rawValue, use: self.login)
        usersRouter.post(Verb.register.rawValue, use: self.register)
        usersRouter.post(Verb.forgotPassword.rawValue, use: self.forgotPassword)
        usersRouter.get(Verb.activation.rawValue, use: self.activation)
        
        let usersProtectedRouter = protectedRouter.grouped("\(controllerVersion)/\(pathPrefix)")
        usersProtectedRouter.get(Verb.me.rawValue, use: self.me)
        usersProtectedRouter.put(Verb.me.rawValue, use: self.update)
        usersProtectedRouter.get("", use: self.all)
        usersProtectedRouter.put("",String.parameter, use: self.updateUser)
        usersProtectedRouter.delete("",String.parameter, use: self.deleteUser)
    }
}
