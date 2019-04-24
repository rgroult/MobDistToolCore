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
    
    //POST 'in/artifacts/{apiKey}/{branch}/{version}/{artifactName}
    func createArtifactByApiKey(_ req: Request) throws -> Future<ArtifactDto> {
        let apiKey = try req.parameters.next(String.self)
        let branch = try req.parameters.next(String.self)
        let version = try req.parameters.next(String.self)
        let artifactName = try req.parameters.next(String.self)
        let sortIdentifier = req.http.headers["X_MDT_sortIdentifier"].last
        let metaTagsHeader = req.http.headers["X_MDT_metaTags"].last
        let metaTags:[String : String]?
        if let metaTagsHeader = metaTagsHeader {
            metaTags = try? JSONDecoder().decoder(from: metaTagsHeader.convertToData()) as! [String : String]
        }else {
           metaTags = nil
        }
        let context = try req.context()
        return try findApplication(apiKey: apiKey, into: context)
            .flatMap({ app  in
                guard let app = app else { throw ApplicationError.notFound }
                return try createArtifact(app: app, name: artifactName, version: version, branch: branch, sortIdentifier: sortIdentifier, tags: metaTags, into: context)})
            .map{ArtifactDto(from: $0, content: .full)}
    }
    
    //DELETE 'in/artifacts/{apiKey}/{branch}/{version}/{artifactName}
    func deleteArtifactByApiKey(_ req: Request) throws -> Future<MessageDto> {
        let apiKey = try req.parameters.next(String.self)
        let branch = try req.parameters.next(String.self)
        let version = try req.parameters.next(String.self)
        let artifactName = try req.parameters.next(String.self)
        let context = try req.context()
        
        return try findApplication(apiKey: apiKey, into: context)
            .flatMap({ app  in
                guard let app = app else { throw ApplicationError.notFound }
                return try findArtifact(app: app, branch: branch, version: version, name: artifactName, into: context)})
            .flatMap({ artifact in
                guard let artifact = artifact else { throw ArtifactError.notFound }
                return try App.deleteArtifact(by: artifact, into: context)})
            .map { MessageDto(message: "Artifact Deleted \($0)")}
        
    }
    
/*return try req.content.decode(ArtifactCreateUpdateDto.self)
 .flatMap({ artifactCreateUpdateDto in
 return try findApplication(apiKey: apiKey, into: context)
 .flatMap({ app  in
 guard let app = app else { throw ApplicationError.notFound }
 return try createArtifact(app: app, name: artifactCreateUpdateDto.name, version: artifactCreateUpdateDto.version, branch: artifactCreateUpdateDto.branch, sortIdentifier: artifactCreateUpdateDto.sortIdentifier, tags: artifactCreateUpdateDto.metaDataTags, into: context)})})
 .map{ArtifactDto(from: $0, content: .full)}
 */
    
/*let uuid = try req.parameters.next(UUID.self)
 let context = try /Users/rgroult/Developments/Perso/MobDistToolSwift/Sources/App/Controllers/Artifacts/ArtifactsController+Routing.swiftreq.context()
 return try retrieveUser(from:req)
 .flatMap{user -> Future<ApplicationDto> in
 guard let user = user else { throw Abort(.unauthorized)}
 return try req.content.decode(ApplicationUpdateDto.self)*/
    
    //POST 'artifacts/{appUUID} // path: 'artifacts/{apiKey}/{_branch}/{_version}/{_artifactName}')
    //PUT 'artifacts/{idArtifact}/info
    //PUT 'artifacts/{idArtifact}/file
    //GET 'artifacts/{idArtifact}/info
    //GET 'artifacts/{idArtifact}/file
    //DELETE 'artifacts/{idArtifact}
    
    func deleteArtifact(_ req: Request) throws -> String {
        throw "Not implemented"
    }
    
    //GET 'artifacts/{idArtifact}/file')
    func artifactDownloadInfo(_ req: Request) throws -> String {
         throw "Not implemented"
    }
    
    //PUT artifacts/{idArtifact}/file
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
