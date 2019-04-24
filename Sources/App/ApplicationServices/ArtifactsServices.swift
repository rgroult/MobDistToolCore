//
//  ArtifactsServices.swift
//  App
//
//  Created by Rémi Groult on 25/02/2019.
//

import Vapor
import Meow

enum ArtifactError: Error {
    case notFound
}

extension ArtifactError:Debuggable {
    var reason: String {
        switch self {
        case .notFound:
            return "ArtifactError.notFound"
        }
    }
    
    var identifier: String {
        return "ArtifactError"
    }
}

func findArtifact(byUUID:String,into context:Meow.Context) throws -> Future<Artifact?> {
    return context.findOne(Artifact.self, where: Query.valEquals(field: "uuid", val: byUUID))
}

func findArtifact(app:MDTApplication,branch:String,version:String,name:String,into context:Meow.Context) throws -> Future<Artifact?>{
    let userQuery: Document = ["$eq": app._id]
    let query = Query.and([Query.custom(userQuery),
                           Query.valEquals(field: "branch", val: branch),
                           Query.valEquals(field: "version", val: version),
                           Query.valEquals(field: "name", val: name)])
     return context.findOne(Artifact.self, where: query)
}

func deleteArtifact(by artifact:Artifact,into context:Meow.Context) -> Future<Void>{
    return context.delete(artifact)
}

func createArtifact(app:MDTApplication,name:String,version:String,branch:String,sortIdentifier:String?,tags:[String:String]?,into context:Meow.Context)throws -> Future<Artifact>{
    let createdArtifact = Artifact(app: app, name: name, version: version, branch: branch)
    createdArtifact.sortIdentifier = sortIdentifier
    if let tags = tags, let encodedTags = try? JSONEncoder().encode(tags) {
        createdArtifact.metaDataTags = String(data: encodedTags, encoding: .utf8)
    }
    return  createdArtifact.save(to: context).map{ createdArtifact}
}

