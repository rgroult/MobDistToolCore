//
//  ArtifactsController.swift
//  App
//
//  Created by Rémi Groult on 18/02/2019.
//

import Vapor
import Vapor
import Swiftgger
import Meow


final class ArtifactsController:BaseController  {
    static let lastVersionBranchName = "@@@@LAST####"
    static let lastVersionName = "latest"
    
    init(apiBuilder:OpenAPIBuilder) {
        super.init(version: "v2", pathPrefix: "Artifacts", apiBuilder: apiBuilder)
    }
    
    //'artifacts/{idArtifact}
    func deleteArtifact(_ req: Request) throws -> String {
        throw "Not implemented"
    }
    
    // 'artifacts/{idArtifact}/download')
    func artifactDownloadInfo(_ req: Request) throws -> String {
         throw "Not implemented"
    }
    
    func uploadArtifact(_ req: Request) throws -> String {
        return "OK"
    }
    
    
    
    //MARK: - ApiKey methods
    
//    @ApiMethod( method: 'POST', path: 'artifacts/{apiKey}/{_branch}/{_version}/{_artifactName}')
    
//    @ApiMethod(method: 'DELETE', path: 'artifacts/{apiKey}/{_branch}/{_version}/{_artifactName}')
    
    
//@ApiMethod(method: 'POST', path: 'artifacts/{apiKey}/last/{_artifactName}')
    
 // @ApiMethod(method: 'DELETE', path: 'artifacts/{apiKey}/last/{_artifactName}')
    
 //@ApiMethod(method: 'GET', path: 'app/{appId}/icon')
    
    //@ApiMethod(method: 'GET', path: 'artifacts/{idArtifact}/ios_plist')
    
    
    func uploadArtifactOLD(_ req: Request) throws -> Future<String> {
        struct UploadArtifact:Content {
            let artifactFile: File
            let sortIdentifier:String?
            let jsonTags:String?
        }
        print("Upload Done")
        let artifactFile = try req.content.decode(UploadArtifact.self,maxSize:1024*1024*1024*1024)
            .map({ artifact -> String in
                print("Upload Artifact \(artifact)")
                return "OK"
            })
        
        return artifactFile
          /*  .flatMap { artifact -> EventLoopFuture<T> in
                print(artifact)
                
        }*/
    }
}
