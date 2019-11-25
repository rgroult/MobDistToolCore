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
        case artifactFile(uuid:String)
        case artifactiOSManifest(uuid:String)
        case deployScript(apiKeyPathName:String)
        var uri:String {
            switch self {
            case .artifacts(let apiKeyPathName, let branchPathName, let versionPathName,let namePathName):
                return "{\(apiKeyPathName)}/{\(branchPathName)}/{\(versionPathName)}/{\(namePathName)}"
            case .lastArtifacts(let apiKeyPathName,let namePathName):
                return "{\(apiKeyPathName)}/latest/{\(namePathName)}"
            case .artifactDownloadInfo:
                return "{uuid}/download"
            case .artifactFile(let uuid):
                return "{\(uuid)}/file"
            case .artifactiOSManifest(let uuid):
                return "{\(uuid)}/ios_plist"
            case .deployScript(let apiKeyPathName):
                return "{\(apiKeyPathName)}/deploy"
            }
        }
        var path:String {
            switch self {
          /*  case .artifacts(let apiKeyPathName, let branchPathName, let versionPathName,let namePathName):
                return "\(apiKeyPathName)}/{\(branchPathName)/\(versionPathName)/\(namePathName)"
            case .lastArtifacts(let apiKeyPathName,let namePathName):
                return "\(apiKeyPathName)/latest/\(namePathName)"
            case .artifactDownloadInfo:
                return "{uuid}/download"*/
            case .artifactFile(let uuid):
                return "\(uuid)/file"
            case .artifactiOSManifest(let uuid):
                return "\(uuid)/ios_plist"
            default:
                return "XXX"
            }
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
        
        //GET {artifact uuid}/file
        artifactRouter.get("", String.parameter ,PathComponent.constant("file"),  use: self.downloadArtifactFile)
        //GET {artifact uuid}/ios_plist
        artifactRouter.get("", String.parameter ,PathComponent.constant("ios_plist"),  use: self.downloadArtifactManifest)
        
        //protected
        //GET {artifact uuid}/download
        let protectedArtifactRouter = protectedRouter.grouped("\(controllerVersion)/\(pathPrefix)")
        protectedArtifactRouter.get("",String.parameter,PathComponent.constant("download"), use:self.downloadInfo)
    }
}

