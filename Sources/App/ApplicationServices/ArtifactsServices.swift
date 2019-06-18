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
    case alreadyExist
    case notFound
    case storageError
    case invalidContentType
    case invalidContent
}

extension ArtifactError:Debuggable {
    var reason: String {
        switch self {
        case .notFound:
            return "ArtifactError.notFound"
        case .storageError:
            return "ArtifactError.storageError"
        case .invalidContentType:
            return "ArtifactError.invalidContentType"
        case .alreadyExist:
            return "ArtifactError.alreadyExist"
        case .invalidContent:
            return "ArtifactError.invalidContent"
        }
    }
    
    var identifier: String {
        return "ArtifactError"
    }
}

func findArtifact(byUUID:String,into context:Meow.Context) throws -> Future<Artifact?> {
    return context.findOne(Artifact.self, where: Query.valEquals(field: "uuid", val: byUUID))
}

func findArtifact(byID:String,into context:Meow.Context) throws -> Future<Artifact?> {
    return context.findOne(Artifact.self, where: Query.valEquals(field: "_id", val: try ObjectId(byID)))
}

func findArtifact(app:MDTApplication,branch:String,version:String,name:String,into context:Meow.Context) throws -> Future<Artifact?>{
   // let userQuery: Document = ["$eq": app._id]
    let query = Query.and([//Query.custom(userQuery),
                            Query.valEquals(field: "application", val: app._id),
                           Query.valEquals(field: "branch", val: branch),
                           Query.valEquals(field: "version", val: version),
                           Query.valEquals(field: "name", val: name)])
     return context.findOne(Artifact.self, where: query)
}

// NB: Pagination is made by creationDate
func findArtifacts(app:MDTApplication,pageIndex:Int?,limitPerPage:Int?,selectedBranch:String?, excludedBranch:String?,into context:Meow.Context) throws -> MappedCursor<FindCursor, Artifact>{
    var queryConditions = [Query.valEquals(field: "application", val: app._id)]
    
    if let branch = selectedBranch {
        queryConditions.append(Query.valEquals(field: "branch", val: branch))
    }
    
    if let excludedBranch = excludedBranch {
        queryConditions.append(Query.valNotEquals(field: "branch", val: excludedBranch))
    }
    
    let query = Query.and(queryConditions)
    
    var mappedCursorResult = context.find(Artifact.self, where: query).sort(Sort([("creationDate", SortOrder.descending)]))
    
    //both of them are needed: How to compute page index without size
    if let pageIndex = pageIndex, let limitPerPage = limitPerPage {
        let page = max(0,pageIndex)
        let numberToSkip = (page)*limitPerPage
        mappedCursorResult = mappedCursorResult.skip(numberToSkip).limit(limitPerPage)
    }
    return mappedCursorResult
}

// NB: Search max artifact version sort by "sortIdentifier"
func searchMaxArtifact(app:MDTApplication,branch:String,artifactName:String,into context:Meow.Context) ->  Future<Artifact?> {
    let query = Query.and([Query.valEquals(field: "application", val: app._id),
        Query.valEquals(field: "branch", val: branch),
        Query.valEquals(field: "name", val: artifactName)])
    
    return context.find(Artifact.self, where: query).sort(Sort([("sortIdentifier", SortOrder.descending)])).getFirstResult()
}


func isArtifactAlreadyExist(app:MDTApplication,branch:String,version:String,name:String,into context:Meow.Context) throws -> Future<Bool>{
    return try findArtifact(app: app, branch: branch, version: version, name: name, into: context)
        .map{$0 != nil }
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
    createdArtifact.sortIdentifier = sortIdentifier ?? version
    if let tags = tags, let encodedTags = try? JSONEncoder().encode(tags) {
        createdArtifact.metaDataTags = String(data: encodedTags, encoding: .utf8)
    }
    return createdArtifact
}

func retrieveArtifactData(artifact:Artifact,storage:StorageServiceProtocol,into context:Meow.Context) throws -> Future<StoredResult> {
    guard let storageUrl = artifact.storageInfos else {throw ArtifactError.storageError}
    return try storage.getStoredFile(storedIn: storageUrl, into: context.eventLoop)
}

func storeArtifactData(data:Data,filename:String,contentType:String?, artifact:Artifact, storage:StorageServiceProtocol,into context:Meow.Context) throws -> Future<Artifact>{
    //let cacheDirectory = URL(fileURLWithPath: "/tmp/MDT/")
    let temporaryFile = "\(NSTemporaryDirectory())\(filename)_\(random(10)).tmp"  // cacheDirectory.appendingPathComponent("\(filename)_\(random(10)).tmp", isDirectory: false)
    
    let temporaryFileUrl = URL(fileURLWithPath: temporaryFile)
    try data.write(to: temporaryFileUrl)
    
    guard let file =  FileHandle(forReadingAtPath: temporaryFile) else {throw ArtifactError.storageError}
    //TO DO Extract metadata
    //try extractFileMetaData(filePath: temporaryFile)
    
    return artifact.application.resolve(in: context)
        .flatMap({ app  in
            return try extractFileMetaData(filePath: temporaryFile,applicationType: app.platform,into: context)
                .flatMap({metadata in
                    let storageInfo = StorageInfo(applicationName: app.name, platform: app.platform, version: artifact.version, uploadFilename: filename, uploadContentType: contentType)
                    return try storage.store(file: file, with: storageInfo, into: context.eventLoop)
                        .map({ storageUrl in
                            //update artifact
                            artifact.storageInfos = storageUrl
                            artifact.filename = filename
                            artifact.contentType = contentType
                            artifact.size = data.count
                            artifact.addMetaData(metaData: metadata)
                            return artifact
                        })
                })
        })
    
}

func saveArtifact(artifact:Artifact,into context:Meow.Context) throws -> Future<Artifact>{
    return artifact.save(to: context).map{artifact}
}

func extractFileMetaData(filePath:String,applicationType:Platform,into context:Meow.Context)throws -> Future<[String:String]> {
    switch applicationType {
    case .ios:
        return try extractIpaMetaData(IpaFilePath:filePath,into: context)
    case .android:
        return try extractApkMetaData(ApkFilePath:filePath,into: context)
    }
}

private func  extractIpaMetaData(IpaFilePath:String,into context:Meow.Context)throws -> Future<[String:String]>{
    //IPA : unzip -p pathIPA *.app/Info.plist
    let iosPlistKeysToExtract = ["CFBundleIdentifier","CFBundleVersion","MinimumOSVersion","CFBundleShortVersionString"]
    let task = Process()
   // task.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
    task.launchPath = "/usr/bin/unzip"
    task.arguments = ["-p",IpaFilePath,"*.app/Info.plist"]
    let outputPipe = Pipe()
    task.standardOutput = outputPipe
    
    do {
       // try task.run()
        task.launch()
        let plistBinary = outputPipe.fileHandleForReading.readDataToEndOfFile()
        var plistFormat = PropertyListSerialization.PropertyListFormat.binary
        let propertyList = try PropertyListSerialization.propertyList(from: plistBinary, options: [], format: &plistFormat) as! [String:Any]
        var metaData = [String:String]()
        iosPlistKeysToExtract.forEach { key in
            metaData[key] = "\(propertyList[key] ?? "")"
        }
        return context.eventLoop.newSucceededFuture(result: metaData)
    }catch {
        throw ArtifactError.invalidContent
    }
}

private func  extractApkMetaData(ApkFilePath:String,into context:Meow.Context)throws -> Future<[String:String]>{
    throw "not implemented"
}
/*
func extractFileMetaData(filePath:String) throws /*-> Future<[String:String]> */{
    let iosPlistKeysToExtract = ["CFBundleIdentifier","CFBundleVersion","MinimumOSVersion","CFBundleShortVersionString"]
    
    //APK : aapk d xmltree pathAPK AndroidManifest.xml
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
    task.arguments = ["-p",filePath,"*.app/Info.plist"]
    let outputPipe = Pipe()
    task.standardOutput = outputPipe
    
    
    do {
        task.terminationHandler = { process  in
            print("Task Done")
        }
        
     try task.run()
        let plistBinary = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: plistBinary, as: UTF8.self)
        var plistFormat = PropertyListSerialization.PropertyListFormat.binary
        let propertyList = try PropertyListSerialization.propertyList(from: plistBinary, options: [], format: &plistFormat) as? [String:Any]
        print("Output : \(propertyList)")
        
    }catch {
        throw ArtifactError.invalidContent
    }
    print("End of function")
}*/

