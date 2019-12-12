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
        case favoritesApp
        case specificApp(pathName:String)
        case specificAppIcon(pathName:String)
        case specificAppVersions(pathName:String)
        case specificAppLatestVersions(pathName:String)
        case specificAppVersionsGrouped(pathName:String)
        case specificAppLatestVersionsGrouped(pathName:String)
        case specificAppAdmins(pathName:String,email:String)
        case maxVersion(pathName:String,branch:String,versionName:String)
        case permanentLinks
        case permanentLinkInstall
        var uri:String {
            switch self {
            case .allApplications:
                return ""
            case .favoritesApp:
                return "favorites"
            case .specificApp(let pathName):
                return "{\(pathName)}"
            case .specificAppIcon(let pathName):
                return "{\(pathName)}/icon"
            case .specificAppVersions(let pathName):
                return "{\(pathName)}/versions"
            case .specificAppVersionsGrouped(let pathName):
                return "{\(pathName)}/versions/grouped"
            case .specificAppLatestVersions(let pathName):
                return "{\(pathName)}/versions/latest"
            case .specificAppLatestVersionsGrouped(let pathName):
                return "{\(pathName)}/versions/latest/grouped"
            case .specificAppAdmins(let pathName, let email):
                 return "{\(pathName)}/adminUsers/{\(email)}"
            case .maxVersion(let pathName, let branch, let versionName):
                return "{\(pathName)}/maxversion/{\(branch)}/{\(versionName)}"
            case .permanentLinks:
                return "{uuid}/links"
            case .permanentLinkInstall:
                return "permanentLink"
            }
        }
    }
    
    func configure(with router: Router, and protectedRouter:Router){
        let appRouter = router.grouped("\(controllerVersion)/\(pathPrefix)")
        appRouter.get("",String.parameter,PathComponent.constant("icon"), use:self.iconApplication)
        //{appUUID}/maxversion/{branch}/{name}
        appRouter.get("",String.parameter,PathComponent.constant("maxversion"),String.parameter,String.parameter, use:self.maxVersion)
        
        let protectedAppsRouter = protectedRouter.grouped("\(controllerVersion)/\(pathPrefix)")
        protectedAppsRouter.get("", use : self.applications)
        protectedAppsRouter.post("", use: self.createApplication)
        protectedAppsRouter.get("", PathComponent.constant(Verb.favoritesApp.uri), use : self.applicationsFavorites)
        protectedAppsRouter.put("", String.parameter /*PathComponent.parameter("uuid")*/,  use: self.updateApplication)
        protectedAppsRouter.get("", String.parameter /*PathComponent.parameter("uuid")*/,  use: self.applicationDetail)
        protectedAppsRouter.delete("", String.parameter /*PathComponent.parameter("uuid")*/,  use: self.deleteApplication)
        //application versions
        protectedAppsRouter.get("",String.parameter,PathComponent.constant("versions"), use:self.getApplicationVersions)
        protectedAppsRouter.get("",String.parameter,PathComponent.constant("versions"),PathComponent.constant("grouped"), use:self.getApplicationVersionsGrouped)
    
        protectedAppsRouter.get("",String.parameter,PathComponent.constant("versions"),PathComponent.constant("latest"), use:self.getApplicationLastVersions)
       // protectedAppsRouter.get("",String.parameter,PathComponent.constant("versions"),PathComponent.constant("latest"),PathComponent.constant("grouped"), use:self.getApplicationLastVersionsGrouped)
        //admin user
        protectedAppsRouter.put("", PathComponent.parameter("uuid"),PathComponent.constant("adminUsers"),String.parameter,/*PathComponent.parameter("email"),*/ use: self.addAdminUser)
        protectedAppsRouter.delete("", PathComponent.parameter("uuid"),PathComponent.constant("adminUsers"),String.parameter,/*PathComponent.parameter("email"),*/ use: self.deleteAdminUser)
        //links
        protectedAppsRouter.get("",String.parameter, PathComponent.parameter("links"), use: self.applicationPermanentLinks)
        protectedAppsRouter.post("",String.parameter, PathComponent.parameter("links"), use: self.createApplicationPermanentLink)
        protectedAppsRouter.delete("",String.parameter, PathComponent.parameter("links"), use: self.deleteApplicationPermanentLink)
        router.get("", PathComponent.constant(Verb.permanentLinkInstall.uri), use: self.installPermanentLink)
    }
}
