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
// Find artifacts
func findArtifacts(app:MDTApplication,selectedBranch:String?, excludedBranch:String?,into context:Meow.Context) throws -> (Query,MappedCursor<FindCursor, Artifact>){
    var queryConditions = [Query.valEquals(field: "application", val: app._id)]
    
    if let branch = selectedBranch {
        queryConditions.append(Query.valEquals(field: "branch", val: branch))
    }
    
    if let excludedBranch = excludedBranch {
        queryConditions.append(Query.valNotEquals(field: "branch", val: excludedBranch))
    }
    
    let query = Query.and(queryConditions)
    
    return (query,context.find(Artifact.self, where: query))
}

func findDistinctsBranches(app:MDTApplication,into context:Meow.Context) -> Future<[String]> {
    var queryConditions = [Query.valEquals(field: "application", val: app._id)]
    //excluse latest
    queryConditions.append(Query.valNotEquals(field: "branch", val: lastVersionBranchName))
    let query = Query.and(queryConditions)
    let keypath:KeyPath<Artifact,String> =  \Artifact.branch
    return context.distinct(Artifact.self, on:keypath, where: ModelQuery(query))
}

/*
 /// ```swift
 /// collection.aggregate()
 ///     .match("status" == "A")
 ///     .group(id: "$cust_id", ["total": .sum("$amount"))
 ///     .forEach { result in ... }
 /// ```

db.getCollection("MDTArtifact").aggregate([
    { $match : { application : ObjectId("59197088a889ce6afd6f1edb") } },
    { $match : { branch : { "$ne" : "@@@@LAST####"} } },
    { $group : {
        _id : "$sortIdentifier" ,
        date : { $min : "$creationDate"},
        version: { $first : "$version" },
        artifacts : { $push: "$$ROOT" }
        }}
]);
 */

func findAndSortArtifacts(app:MDTApplication,selectedBranch:String?, excludedBranch:String?,into context:Meow.Context) throws -> (MappedCursor<AggregateCursor<Document>,ArtifactGrouped>,Future<Int>) {
    var cursor = context.manager.collection(for: Artifact.self).aggregate()
        .match("application" == app._id)
        
    if let branch = selectedBranch {
        cursor = cursor.match("branch" == branch)
    }
    
    if let excludedBranch = excludedBranch {
        cursor = cursor.match("branch" != excludedBranch)
    }
    
    let idPrimitive = Document(dictionaryLiteral:("sortIdentifier" , "$sortIdentifier"), ("branch" , "$branch"))
    cursor = cursor.group(id: idPrimitive , fields: ["date" : .max("$createdAt"),"version" : .first("$version"),"artifacts" : .push("$$ROOT")])
    return (cursor.decode(ArtifactGrouped.self),cursor.count())
}

// NB: Pagination is made by creationDate
/*func findArtifacts(app:MDTApplication,pageIndex:Int?,limitPerPage:Int?,selectedBranch:String?, excludedBranch:String?,into context:Meow.Context) throws -> MappedCursor<FindCursor, Artifact>{
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
}*/

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

func deleteArtifact(by artifact:Artifact,storage:StorageServiceProtocol,into context:Meow.Context) -> Future<Void>{
    let storageUrl = artifact.storageInfos
    return context.delete(artifact)
        //delete store
        .flatMap { _ in
            if let storageUrl = storageUrl {
                return try storage.deleteStoredFileStorageId(storedIn: storageUrl, into: context.eventLoop)
            }else {
                return context.eventLoop.newSucceededFuture(result: ())
            }
    }
}

func deleteAllArtifacts(app:MDTApplication,storage:StorageServiceProtocol,into context:Meow.Context) -> Future<Void>{
    let query = Query.valEquals(field: "application", val: app._id)

    return context.find(Artifact.self,where: query).sequentialForEach { artifact -> EventLoopFuture<Void> in
        return deleteArtifact(by: artifact, storage: storage, into: context)
    }
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
                            //delete temporary file
                            file.closeFile()
                            try? FileManager.default.removeItem(at: temporaryFileUrl)
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
        #if os(Linux)
            try task.run()
        #else
            task.launch()
        #endif
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
    let task = Process()
    #if os(Linux)
    task.launchPath = "/usr/bin/aapt"
    #else
    task.launchPath = "/usr/local/bin/aapt"
    #endif
    task.arguments = ["d", "xmltree",ApkFilePath, "AndroidManifest.xml"]
    let outputPipe = Pipe()
    task.standardOutput = outputPipe
    do {
        print("before Manifest")
        #if os(Linux)
        try task.run()
        #else
        task.launch()
        #endif
        let manifestContent = String(data:outputPipe.fileHandleForReading.readDataToEndOfFile(),encoding: .utf8)
        guard let allLines = manifestContent?.split(separator: "\n") else { throw ArtifactError.invalidContent }
        var metaDataResult = [String:String]()
        for rawLine in allLines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            switch line {
            case _ where  line.hasPrefix("A: package"):
                //A: package="com.testdroid.sample.android" (Raw: "com.testdroid.sample.android")
                guard let packageName = apkExtractString(from: line) else { continue }
                metaDataResult["PACKAGE_NAME"] = packageName
                
            case _ where  line.hasPrefix("A: android:versionCode"):
                //A: android:versionCode(0x0101021b)=(type 0x10)0x1
                guard let versionCode = apkExtractHexVersion(from:line) else { continue }
                metaDataResult["VERSION_CODE"] = versionCode
            
            case _ where  line.hasPrefix("A: android:versionName"):
                //A: android:versionName(0x0101021c)="0.3" (Raw: "0.3")
                guard let version = apkExtractString(from: line) else { continue }
                metaDataResult["VERSION_NAME"] = version
                
            case _ where  line.hasPrefix("A: android:minSdkVersion"):
                // A: android:minSdkVersion(0x0101020c)=(type 0x10)0xe
                guard let versionCode = apkExtractHexVersion(from:line) else { continue }
                metaDataResult["MIN_SDK"] = versionCode
                
            case _ where  line.hasPrefix("A: android:maxSdkVersion"):
                //A: android:maxSdkVersion(0x01010330)=(type 0x10)0x12
                guard let versionCode = apkExtractHexVersion(from:line) else { continue }
                metaDataResult["MAX_SDK"] = versionCode
                
            case _ where  line.hasPrefix("A: android:targetSdkVersion"):
                //A: android:targetSdkVersion(0x01010270)=(type 0x10)0x13
                guard let versionCode = apkExtractHexVersion(from:line) else { continue }
                metaDataResult["TARGET_SDK"] = versionCode
                
            default:
                ()
            }
        }
        
        return context.eventLoop.newSucceededFuture(result:metaDataResult)
        
    }catch {
        throw ArtifactError.invalidContent
    }
}
private func apkExtractHexVersion(from stringValue:String) -> String? {
    guard let lastIndex = stringValue.lastIndex(of: ")") else { return nil }
    guard let hexVersion = Int( stringValue[stringValue.index(lastIndex,offsetBy: 3 /* remove')' and the 0x */)..<stringValue.endIndex], radix: 16) else { return nil }
    return  "\(hexVersion)"
}

private func apkExtractString(from line:String) -> String? {
    //remove prefix
    var removedPrefix = line.drop { $0 != "\""}
    removedPrefix = removedPrefix.dropFirst()
    guard let nextIndex = removedPrefix.firstIndex(of: "\"") else { return nil }
    return String(removedPrefix[removedPrefix.startIndex..<nextIndex])
}

