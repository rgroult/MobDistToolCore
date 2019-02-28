//
//  StorageMiddlewareProtocol.swift
//  App
//
//  Created by Rémi Groult on 27/02/2019.
//

import Vapor
import Foundation

enum storedResult {
    case asFile(file:Foundation.FileHandle)
    case asUrI(url:URL)
}

enum StorageError:Error {
    case badFormat, notFound
}

protocol StorageServiceProtocol: Service  {
    var storageIdentifier:String { get }
    
    func  initializeStore(with config:[String:String], into eventLoop:EventLoop) throws-> Future<Bool>
    
    func store(file:Foundation.FileHandle,inside artifact:Artifact, into eventLoop:EventLoop) throws-> Future<StorageAccessUrl>
    
    func getStoredFile(storedIn artifact:Artifact, into eventLoop:EventLoop) throws-> Future<storedResult>
    
    func extractStorageId(storageInfo:String) throws-> String
}

extension StorageServiceProtocol {
    internal func extractStorageId(storageInfo:StorageAccessUrl) throws  -> String {
        let scheme = "\(storageIdentifier)://"
        guard storageInfo.hasPrefix(scheme) else { throw StorageError.badFormat }
        
        return String(storageInfo.dropFirst(scheme.count))
    }
}
