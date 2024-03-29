//
//  StorageMiddlewareProtocol.swift
//  App
//
//  Created by Rémi Groult on 27/02/2019.
//

import Vapor
import Foundation

enum StoredResult {
    case asFile(file:Foundation.FileHandle)
    case asUrI(url:URL)
}

enum StorageError:Error {
    case badFormat
    case notFound
    case storeError(from:Error)
    case deleteError(from:Error)
    case internalError
}

protocol StorageServiceProtocol/*: Service*/  {
    var storageIdentifier:String { get }
    
    func  initializeStore(with config:[String:String]) throws-> Bool
    
    func store(file:Foundation.FileHandle, with info:StorageInfo, into eventLoop:EventLoop)-> EventLoopFuture<StorageAccessUrl>
    
    func getStoredFile(storedIn:StorageAccessUrl, into eventLoop:EventLoop)-> EventLoopFuture<StoredResult>
    
    func extractStorageId(storageInfo:String) throws-> String
    
    func deleteStoredFileStorageId(storedIn:StorageAccessUrl, into eventLoop:EventLoop) -> EventLoopFuture<Void>
}

extension StorageServiceProtocol {
    internal func extractStorageId(storageInfo:StorageAccessUrl) throws  -> String {
        let scheme = "\(storageIdentifier)://"
        guard storageInfo.hasPrefix(scheme) else { throw StorageError.badFormat }
        
        return String(storageInfo.dropFirst(scheme.count))
    }
    
    internal func makeStorageAccessUrl(from:String) -> String{
        return "\(storageIdentifier)://\(from)"
    }
}

struct StorageServiceProtocolKey: StorageKey {
    typealias Value = StorageServiceProtocol
}

extension Application {
    var storageService: StorageServiceProtocol? {
        get {
            self.storage[StorageServiceProtocolKey.self]
        }
        set {
            self.storage[StorageServiceProtocolKey.self] = newValue
        }
    }
}

extension Request {
    func storageService() throws -> StorageServiceProtocol  {
        guard let service =  application.storageService else { throw Abort(.internalServerError) }
        return service
    }
}
