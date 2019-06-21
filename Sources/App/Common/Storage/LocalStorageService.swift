//
//  LocalStorageMiddleware.swift
//  App
//
//  Created by Rémi Groult on 28/02/2019.
//

import Vapor
import Foundation

struct StorageInfo {
    let applicationName:String
    let platform:Platform
    let version:String
    let uploadFilename:String?
    let uploadContentType:String?
}
fileprivate let bufferSize = 1024*1024 //1M
    
final class LocalStorageService: StorageServiceProtocol {
    var storageIdentifier = "LocalStorage"
    private var rootStoragePath = ""
    let fileQueue = DispatchQueue.init(label: "LocalStorageService", qos: .`default`)
    
    func initializeStore(with config: [String : String]) throws -> Bool {
        guard let rootPath = config["RootDirectory"] else  { throw "not implemented" }
        rootStoragePath = rootPath
        //test if rootPath exist
        let fileManager = FileManager.default
        var isDirectory:ObjCBool = false
        if !fileManager.fileExists(atPath: rootPath, isDirectory: &isDirectory) {
            //create directory
            try fileManager.createDirectory(atPath: rootPath, withIntermediateDirectories: true, attributes: nil)
        }else {
            //check if it'a a directory
            guard isDirectory.boolValue else { throw "\(rootPath) does not seems to be a directory"}
            //check if directory seems to be writable
            guard fileManager.createFile(atPath: "\(rootPath)/testLocalStorage", contents: nil, attributes: nil) else { throw "\(rootPath) does not seems to be a writable directory" }
        }
        //check if directory seems to be writable
        //guard fileManager.isWritableFile(atPath: "\(rootPath)/testLocalStorage") else { throw "\(rootPath) does not seems to be a writable directory" }
        
        return true
    }
    
    func store(file: Foundation.FileHandle, with info:StorageInfo, into eventLoop:EventLoop) throws -> EventLoopFuture<StorageAccessUrl> {
        //generate relative Path for file
        var absolutePathName = URL(fileURLWithPath: rootStoragePath)
        absolutePathName.appendPathComponent(info.platform.rawValue)
        absolutePathName.appendPathComponent(info.applicationName)
        absolutePathName.appendPathComponent(info.version)
        
       
        //absolutePathName.appendPathComponent(random(5))
        
        let result = eventLoop.newPromise(of: StorageAccessUrl.self)
        let fileManager = FileManager.default
        //create directory if needed
        try fileManager.createDirectory(at: absolutePathName, withIntermediateDirectories: true, attributes: nil)
        //add random to filename to avoid collision
        absolutePathName.appendPathComponent("\(info.uploadFilename ?? "JohnDoe")\(random(5))")
        
        let storePath = absolutePathName.path
        let resultStoreUrl = makeStorageAccessUrl(from: storePath)
        fileQueue.async {
            do {
                //Create File
                fileManager.createFile(atPath: storePath, contents: nil, attributes: nil)
                let outputFile = try Foundation.FileHandle.init(forWritingTo: absolutePathName)
                //read
                var data = file.readData(ofLength:bufferSize)
                while (data.count > 0) {
                    outputFile.write(data)
                    data = file.readData(ofLength:bufferSize)
                }
                outputFile.synchronizeFile()
                outputFile.closeFile()
                //generate storageAccessUrl
                result.succeed(result: resultStoreUrl)
            }
            catch{
                result.fail(error: StorageError.storeError(from: error))
            }
        }
        
        return result.futureResult
    }
    
    func getStoredFile(storedIn :StorageAccessUrl, into eventLoop:EventLoop) throws -> EventLoopFuture<StoredResult> {
        guard let filenameUrl = URL(string:  try extractStorageId(storageInfo: storedIn)) else { throw StorageError.badFormat }
        guard FileManager.default.fileExists(atPath: filenameUrl.path) else { throw StorageError.notFound }
        guard let url = URL(string:  "file://\(filenameUrl.path)") else { throw StorageError.internalError }
        return eventLoop.newSucceededFuture(result:StoredResult.asUrI(url:url))
      /*  do {
            let fileHandler = try Foundation.FileHandle(forReadingFrom: filename)
            //print(fileHandler.readDataToEndOfFile())
            return eventLoop.newSucceededFuture(result:StoredResult.asFile(file: fileHandler))
        }catch {
            return eventLoop.newFailedFuture(error: StorageError.notFound)
        }*/
    }
    
    func deleteStoredFileStorageId(storedIn:StorageAccessUrl, into eventLoop:EventLoop) throws-> Future<Void>{
        //guard let filename = URL(fileURLWithPath:  try extractStorageId(storageInfo: storedIn)) else { throw StorageError.badFormat }
        let filename = URL(fileURLWithPath:  try extractStorageId(storageInfo: storedIn))
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: filename.path) {
            throw StorageError.notFound
        }
        do {
            try FileManager.default.removeItem(at: filename)
            return eventLoop.newSucceededFuture(result: ())
        }catch {
            throw StorageError.deleteError(from: error)
        }
    }
}
