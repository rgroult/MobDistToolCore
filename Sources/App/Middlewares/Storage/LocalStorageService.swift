//
//  LocalStorageMiddleware.swift
//  App
//
//  Created by Rémi Groult on 28/02/2019.
//

import Vapor
import Foundation


final class LocalStorageService: StorageServiceProtocol {
    var storageIdentifier = "LocalStorage"
    private var rootStoragePath = ""
    
    func initializeStore(with config: [String : String], into eventLoop:EventLoop) throws -> Future<Bool> {
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
        }
        //check if directory seems to be writable
        guard fileManager.isWritableFile(atPath: "\(rootPath)/testLocalStorage") else { throw "\(rootPath) does not seems to be a writable directory" }
        
        return eventLoop.newSucceededFuture(result: true)
    }
    
    func store(file: Foundation.FileHandle, inside artifact: Artifact, into eventLoop:EventLoop) throws -> EventLoopFuture<StorageAccessUrl> {
        //let application = artifact.application.resolve(in: <#T##Context#>)
        //generate relative Path for file
        var relativePath = URL(fileURLWithPath: rootStoragePath)
       // relativePath.appendPathComponent(artifact.)
        throw "not implemented"
    }
    
    func getStoredFile(storedIn artifact: Artifact, into eventLoop:EventLoop) throws -> EventLoopFuture<storedResult> {
          throw "not implemented"
    }
    
}
