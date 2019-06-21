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
        return eventLoop.newSucceededFuture(result: "\(storageIdentifier)://\(info.platform)")
    }
    
    func getStoredFile(storedIn: StorageAccessUrl, into eventLoop: EventLoop) throws -> EventLoopFuture<StoredResult> {
        let resultUrl:URL!
        switch storedIn {
        case "\(storageIdentifier)://\(Platform.ios)":
            resultUrl = URL(string:"https://github.com/bitbar/bitbar-samples/blob/master/apps/ios/calculator.ipa?raw=true")!
        case "\(storageIdentifier)://\(Platform.android)":
            resultUrl = URL(string:"https://github.com/bitbar/bitbar-samples/blob/master/apps/android/testdroid-sample-app.apk?raw=true")!
        default:
            throw  StorageError.notFound
        }
        return eventLoop.newSucceededFuture(result: StoredResult.asUrI(url:resultUrl ))
    }
    
    func deleteStoredFileStorageId(storedIn: StorageAccessUrl, into eventLoop: EventLoop) throws -> EventLoopFuture<Void> {
        return eventLoop.newSucceededFuture(result: ())
    }
    
}
