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
        case artifact(uuid:String)
        case artifactFile(uuid:String)
        case artifactiOSManifest(uuid:String)
        var uri:String {
            switch self {
            case .artifacts(let apiKeyPathName, let branchPathName, let versionPathName,let namePathName):
                return "{\(apiKeyPathName)}/{\(branchPathName)}/{\(versionPathName)}/{\(namePathName)}"
            case .lastArtifacts(let apiKeyPathName,let namePathName):
                return "{\(apiKeyPathName)}/latest/{\(namePathName)}"
            case .artifact(let uuid):
                return "\(uuid)"
            case .artifactFile(let uuid):
                return "\(uuid)/file"
            case .artifactiOSManifest(let uuid):
                return "\(uuid)/ios_plist"
            }
        }
    }
    
    func configure(with router: Router, and protectedRouter:Router){
        let artifactRouter = router.grouped("\(controllerVersion)/\(pathPrefix)")
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

