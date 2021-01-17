//
//  ArtifactsController.swift
//  App
//
//  Created by Rémi Groult on 08/04/2019.
//

import Vapor

extension ArtifactsController {
    enum Verb {
        case artifacts(apiKeyPathName:String,branchPathName:String,versionPathName:String,namePathName:String)
        case lastArtifacts(apiKeyPathName:String,namePathName:String)
        case artifactDownloadInfo
        case artifactFile
        case icon
        case artifactiOSManifest
        case installPage
        case deployScript(apiKeyPathName:String)
        var uri:String {
            switch self {
            case .artifacts(let apiKeyPathName, let branchPathName, let versionPathName,let namePathName):
                return "{\(apiKeyPathName)}/{\(branchPathName)}/{\(versionPathName)}/{\(namePathName)}"
            case .lastArtifacts(let apiKeyPathName,let namePathName):
                return "{\(apiKeyPathName)}/latest/{\(namePathName)}"
            case .artifactDownloadInfo:
                return "{uuid}/download"
            case .artifactFile:
                return "file"
            case .icon:
                return "icon"
            case .artifactiOSManifest:
                return "ios_plist"
            case .installPage:
                return "install"
            case .deployScript(let apiKeyPathName):
                return "{\(apiKeyPathName)}/deploy"
            }
        }
        var path:String {
            switch self {
            case .artifactFile, .artifactiOSManifest, .installPage, .icon:
                return uri
            default:
                return "XXX"
            }
           /* switch self {
          /*  case .artifacts(let apiKeyPathName, let branchPathName, let versionPathName,let namePathName):
                return "\(apiKeyPathName)}/{\(branchPathName)/\(versionPathName)/\(namePathName)"
            case .lastArtifacts(let apiKeyPathName,let namePathName):
                return "\(apiKeyPathName)/latest/\(namePathName)"
            case .artifactDownloadInfo:
                return "{uuid}/download"*/
            case .artifactFile:
                return "file"
            case .artifactiOSManifest:
                return "ios_plist"
                case
            default:
                return "XXX"
            }*/
        }
    }
    
    func configure(with router: RoutesBuilder, and protectedRouter:RoutesBuilder){
        let artifactRouter = router.grouped("\(controllerVersion)/\(pathPrefix)")
        //GET '{apiKey}/deploy
        artifactRouter.get([.parameter("apiKey"),.constant("deploy")], use:self.deploy)
        //POST '{apiKey}/{branch}/{version}/{artifactName}
        artifactRouter.post([.parameter("apiKey"),.parameter("branch"),.parameter("version"),.parameter("artifactName")],  use: self.createArtifactByApiKey)
        //DELETE '{apiKey}/{branch}/{version}/{artifactName}
        artifactRouter.delete([.parameter("apiKey"),.parameter("branch"),.parameter("version"),.parameter("artifactName")],  use: self.deleteArtifactByApiKey)
        
        //POST '{apiKey}/latest/{artifactName}
        artifactRouter.post([.parameter("apiKey"),.constant("latest"),.parameter("artifactName")],  use: self.createLastArtifactByApiKey)
        //DELETE '{apiKey}/latest/{artifactName}
        artifactRouter.delete([.parameter("apiKey"),.constant("latest"),.parameter("artifactName")],  use: self.deleteLastArtifactByApiKey)
        
        //GET /file?token='
        artifactRouter.get([.constant("file")],  use: self.downloadArtifactFile)
        //GET /ios_plist?token='
        artifactRouter.get([.constant("ios_plist")],  use: self.downloadArtifactManifest)
        
        //GET /install?token='
        artifactRouter.get([.constant("install")],  use: self.installArtifactPage)
        //GET /icon?token='
        artifactRouter.get([.constant("icon")],  use: self.downloadArtifactIcon)

        //protected
        //GET {artifact uuid}/download
        let protectedArtifactRouter = protectedRouter.grouped("\(controllerVersion)/\(pathPrefix)")
        //NB: use "apiKey" parameter name instead of "uuid" to resolve conflic into TrieRouter
        protectedArtifactRouter.get([.parameter("apiKey"),.constant("download")], use:self.downloadInfo)
    }
}

