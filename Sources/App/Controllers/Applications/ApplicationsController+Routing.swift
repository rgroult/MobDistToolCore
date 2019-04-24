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
        protectedAppsRouter.post(Verb.applications.rawValue,  use: self.createApplication)
        protectedAppsRouter.put(Verb.applications.rawValue, String.parameter /*PathComponent.parameter("uuid")*/,  use: self.updateApplication)
        protectedAppsRouter.get(Verb.applications.rawValue, String.parameter /*PathComponent.parameter("uuid")*/,  use: self.applicationDetail)
        protectedAppsRouter.delete(Verb.applications.rawValue, String.parameter /*PathComponent.parameter("uuid")*/,  use: self.deleteApplication)
        //admin user
        protectedAppsRouter.put(Verb.applications.rawValue, PathComponent.parameter("uuid"),PathComponent.constant("adminUsers"),String.parameter,/*PathComponent.parameter("email"),*/ use: self.addAdminUser)
        protectedAppsRouter.delete(Verb.applications.rawValue, PathComponent.parameter("uuid"),PathComponent.constant("adminUsers"),String.parameter,/*PathComponent.parameter("email"),*/ use: self.deleteAdminUser)
    }
}
