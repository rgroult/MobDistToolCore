//
//  ApplicationsController+Routing.swift
//  App
//
//  Created by Rémi Groult on 20/02/2019.
//

import Vapor

extension ApplicationsController {
    enum Verb {
        case allApplications
        case specificApp(pathName:String)
        case specificAppVersions(pathName:String)
        case specificAppLatestVersions(pathName:String)
        case specificAppAdmins(pathName:String,email:String)
        var uri:String {
            switch self {
            case .allApplications:
                return ""
            case .specificApp(let pathName):
                return "{\(pathName)}"
            case .specificAppVersions(let pathName):
                return "{\(pathName)}/versions"
            case .specificAppLatestVersions(let pathName):
                return "{\(pathName)}/versions/latest"
            case .specificAppAdmins(let pathName, let email):
                 return "{\(pathName)}/adminUsers/{\(email)}"
            }
        }
    }
    
    func configure(with router: Router, and protectedRouter:Router){
        let protectedAppsRouter = protectedRouter.grouped("\(controllerVersion)/\(pathPrefix)")
        protectedAppsRouter.get("", use : self.applications)
        protectedAppsRouter.post("",  use: self.createApplication)
        protectedAppsRouter.put("", String.parameter /*PathComponent.parameter("uuid")*/,  use: self.updateApplication)
        protectedAppsRouter.get("", String.parameter /*PathComponent.parameter("uuid")*/,  use: self.applicationDetail)
        protectedAppsRouter.delete("", String.parameter /*PathComponent.parameter("uuid")*/,  use: self.deleteApplication)
        //application versions
        protectedAppsRouter.get("",String.parameter,PathComponent.constant("versions"), use:self.getApplicationVersions)
    
        protectedAppsRouter.get("",String.parameter,PathComponent.constant("versions"),PathComponent.constant("latest"), use:self.getApplicationLastVersions)
        //admin user
        protectedAppsRouter.put("", PathComponent.parameter("uuid"),PathComponent.constant("adminUsers"),String.parameter,/*PathComponent.parameter("email"),*/ use: self.addAdminUser)
        protectedAppsRouter.delete("", PathComponent.parameter("uuid"),PathComponent.constant("adminUsers"),String.parameter,/*PathComponent.parameter("email"),*/ use: self.deleteAdminUser)
    }
}
