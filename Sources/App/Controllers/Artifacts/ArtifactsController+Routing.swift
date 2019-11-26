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
            case .artifactFile, .artifactiOSManifest, .installPage:
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
    
    func configure(with router: Router, and protectedRouter:Router){
        let artifactRouter = router.grouped("\(controllerVersion)/\(pathPrefix)")
        //GET '{apiKey}/deploy
        artifactRouter.get("", String.parameter,PathComponent.constant("deploy"), use:self.deploy)
        //POST '{apiKey}/{branch}/{version}/{artifactName}
        artifactRouter.post("", String.parameter ,String.parameter,String.parameter,String.parameter,  use: self.createArtifactByApiKey)
        //DELETE '{apiKey}/{branch}/{version}/{artifactName}
        artifactRouter.delete("", String.parameter ,String.parameter,String.parameter,String.parameter,  use: self.deleteArtifactByApiKey)
        
        //POST '{apiKey}/last/{artifactName}
        artifactRouter.post("", String.parameter ,PathComponent.constant("latest"),String.parameter,  use: self.createLastArtifactByApiKey)
        //DELETE '{apiKey}/last/{artifactName}
        artifactRouter.delete("", String.parameter ,PathComponent.constant("latest"),String.parameter,  use: self.deleteLastArtifactByApiKey)
        
        //GET /file?token='
        artifactRouter.get("",PathComponent.constant("file"),  use: self.downloadArtifactFile)
        //GET /ios_plist?token='
        artifactRouter.get("", PathComponent.constant("ios_plist"),  use: self.downloadArtifactManifest)
        
        //GET /install?token='
        artifactRouter.get("",PathComponent.constant("install"),  use: self.installArtifactPage)
        
        //protected
        //GET {artifact uuid}/download
        let protectedArtifactRouter = protectedRouter.grouped("\(controllerVersion)/\(pathPrefix)")
        protectedArtifactRouter.get("",String.parameter,PathComponent.constant("download"), use:self.downloadInfo)
    }
}

