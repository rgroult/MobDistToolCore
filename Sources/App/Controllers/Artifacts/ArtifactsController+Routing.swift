//
//  ArtifactsController.swift
//  App
//
//  Created by Rémi Groult on 08/04/2019.
//

import Vapor

extension ArtifactsController {
    enum Verb:String {
        case createArtifact = "create"
        case artifacts = ""
    }
    func configure(with router: Router, and protectedRouter:Router){
        let artifactRouter = router.grouped("\(controllerVersion)/\(pathPrefix)")
        //POST 'in/artifacts/{apiKey}/{branch}/{version}/{artifactName}
        artifactRouter.post(Verb.artifacts.rawValue, String.parameter ,String.parameter,String.parameter,String.parameter,  use: self.createArtifactByApiKey)
    }
}

