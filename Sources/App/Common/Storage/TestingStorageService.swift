//
//  TestingStorageService.swift
//  App
//
//  Created by Remi Groult on 10/05/2019.
//

import Vapor
import Foundation

final class TestingStorageService: StorageServiceProtocol {
    var storageIdentifier = "TestingStorage"
    
    func initializeStore(with config: [String : String]) throws -> Bool {
        return true
    }
    
    func store(file: Foundation.FileHandle, with info: StorageInfo, into eventLoop: EventLoop) throws -> EventLoopFuture<StorageAccessUrl> {
        return eventLoop.newSucceededFuture(result: "\(storageIdentifier)://")
    }
    
    func getStoredFile(storedIn: StorageAccessUrl, into eventLoop: EventLoop) throws -> EventLoopFuture<StoredResult> {
        return eventLoop.newSucceededFuture(result: StoredResult.asUrI(url: URL(string:"http://www.apple.com")!))
    }
    
    func deleteStoredFileStorageId(storedIn: StorageAccessUrl, into eventLoop: EventLoop) throws -> EventLoopFuture<Void> {
        return eventLoop.newSucceededFuture(result: ())
    }
    
}
