//
//  ArtifactsController.swift
//  App
//
//  Created by Rémi Groult on 18/02/2019.
//

import Vapor


final class ArtifactsController {
    func uploadArtifact(_ req: Request) throws -> String {
        return "OK"
    }
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
