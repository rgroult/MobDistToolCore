//
//  ArtifactsServices.swift
//  App
//
//  Created by Rémi Groult on 25/02/2019.
//

import Vapor
import Meow
import Foundation

enum ArtifactError: Error {
    case notFound
    case storageError
}

extension ArtifactError:Debuggable {
    var reason: String {
        switch self {
        case .notFound:
            return "ArtifactError.notFound"
        case .storageError:
            return "ArtifactError.storageError"
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
/*
func createArtifact(app:MDTApplication,name:String,version:String,branch:String,sortIdentifier:String?,tags:[String:String]?,into context:Meow.Context)throws -> Future<Artifact>{
    let createdArtifact = Artifact(app: app, name: name, version: version, branch: branch)
    createdArtifact.sortIdentifier = sortIdentifier
    if let tags = tags, let encodedTags = try? JSONEncoder().encode(tags) {
        createdArtifact.metaDataTags = String(data: encodedTags, encoding: .utf8)
    }
    return  createdArtifact.save(to: context).map{ createdArtifact}
}*/

func createArtifact(app:MDTApplication,name:String,version:String,branch:String,sortIdentifier:String?,tags:[String:String]?)throws -> Artifact{
    let createdArtifact = Artifact(app: app, name: name, version: version, branch: branch)
    createdArtifact.sortIdentifier = sortIdentifier
    if let tags = tags, let encodedTags = try? JSONEncoder().encode(tags) {
        createdArtifact.metaDataTags = String(data: encodedTags, encoding: .utf8)
    }
    return createdArtifact
}

func storeArtifactData(data:Data,filename:String,contentType:String?, artifact:Artifact, storage:StorageServiceProtocol,into context:Meow.Context) throws -> Future<Artifact>{
    //let cacheDirectory = URL(fileURLWithPath: "/tmp/MDT/")
    let temporaryFile = "/tmp/MDT/\(filename)_\(random(10)).tmp"  // cacheDirectory.appendingPathComponent("\(filename)_\(random(10)).tmp", isDirectory: false)
    
    guard let file =  FileHandle(forWritingAtPath: temporaryFile) else {throw ArtifactError.storageError}
    //write to temprary Data
    file.write(data)
    //try file.data.write(to: temporaryFile)
    //TO DO Extract metadata
    
    return artifact.application.resolve(in: context)
        .flatMap({ app -> Future<StorageAccessUrl> in
            let storageInfo = StorageInfo(applicationName: app.name, platform: app.platform, version: artifact.version, uploadFilename: filename, uploadContentType: contentType)
            return try storage.store(file: file, with: storageInfo, into: context.eventLoop)
        })
        .map({ storageUrl in
            //update artifact
            artifact.storageInfos = storageUrl
            artifact.filename = filename
            artifact.contentType = contentType
            artifact.size = data.count
            return artifact
        })
}

func saveArtifact(artifact:Artifact,into context:Meow.Context) -> Future<Artifact>{
    return artifact.save(to: context).map{artifact}
}

