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
    
    func configure(with router: RoutesBuilder, and protectedRouter:RoutesBuilder){
        let appRouter = router.grouped("\(controllerVersion)","\(pathPrefix)")
        appRouter.get([.parameter("uuid"),.constant("icon")], use:self.iconApplication)
        appRouter.get([.parameter("uuid"),.constant("maxversion"),.parameter("branch"),.parameter("name")], use:self.maxVersion)
        
        let protectedAppsRouter = protectedRouter.grouped("\(controllerVersion)","\(pathPrefix)")
        protectedAppsRouter.get([], use : self.applications)
        protectedAppsRouter.post([], use: self.createApplication)
        protectedAppsRouter.get( [.constant(Verb.favoritesApp.uri)], use : self.applicationsFavorites)
        protectedAppsRouter.put([.parameter("uuid")],  use: self.updateApplication)
        protectedAppsRouter.get([.parameter("uuid")],  use: self.applicationDetail)
        protectedAppsRouter.delete([.parameter("uuid")],  use: self.deleteApplication)
        //application versions
        protectedAppsRouter.get([.parameter("uuid"),.constant("versions")], use:self.getApplicationVersions)
        protectedAppsRouter.get([.parameter("uuid"),.constant("versions"),.constant("grouped")], use:self.getApplicationVersionsGrouped)
    
        protectedAppsRouter.get([.parameter("uuid"),.constant("versions"),.constant("latest")], use:self.getApplicationLastVersions)
        //admin user
        protectedAppsRouter.put([.parameter("uuid"),.constant("adminUsers"),.parameter("email")], use: self.addAdminUser)
        protectedAppsRouter.delete([.parameter("uuid"),.constant("adminUsers"),.parameter("email")], use: self.deleteAdminUser)
        //links
       // protectedAppsRouter.get([.parameter("uuid"),.parameter("links")], use: self.applicationPermanentLinks)
        protectedAppsRouter.post([.parameter("uuid"),.parameter("links")], use: self.createApplicationPermanentLink)
        protectedAppsRouter.delete([.parameter("uuid"),.parameter("links")], use: self.deleteApplicationPermanentLink)
        router.get([.constant(Verb.permanentLinkInstall.uri)], use: self.installPermanentLink)
    }
}
