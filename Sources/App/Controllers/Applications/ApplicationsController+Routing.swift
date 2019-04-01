//
//  ApplicationsController+Routing.swift
//  App
//
//  Created by Rémi Groult on 20/02/2019.
//

import Vapor

extension ApplicationsController {
    enum Verb:String {
        case applications = ""
    }
    
    func configure(with router: Router, and protectedRouter:Router){
        let protectedAppsRouter = protectedRouter.grouped("\(controllerVersion)/\(pathPrefix)")
        protectedAppsRouter.get(Verb.applications.rawValue, use : self.applications)
        protectedAppsRouter.get(Verb.applications.rawValue, PathComponent.parameter("platform"), use : self.applications)
        protectedAppsRouter.post(Verb.applications.rawValue,  use: self.createApplication)
        protectedAppsRouter.put(Verb.applications.rawValue, PathComponent.parameter("app_uuid"),  use: self.updateApplication)
        /*usersRouter.post(Verb.login.rawValue, use: self.login)
        usersRouter.post(Verb.register.rawValue, use: self.register)
        usersRouter.post(Verb.forgotPassword.rawValue, use: self.forgotPassword)*/
    }
}
