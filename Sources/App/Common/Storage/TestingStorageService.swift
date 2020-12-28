//
//  TestingStorageService.swift
//  App
//
//  Created by Remi Groult on 10/05/2019.
//

import Vapor
import Foundation

final class TestingStorageService: StorageServiceProtocol {
    static let defaultIpaUrl = "https://github.com/bitbar/bitbar-samples/blob/master/apps/ios/calculator.ipa?raw=true"
    static let defaultApkUrl = "https://github.com/bitbar/bitbar-samples/blob/master/apps/android/testdroid-sample-app.apk?raw=true"
    var storageIdentifier = "TestingStorage"
    
    func initializeStore(with config: [String : String]) throws -> Bool {
        return true
    }
    
    func store(file: Foundation.FileHandle, with info: StorageInfo, into eventLoop: EventLoop) throws -> EventLoopFuture<StorageAccessUrl> {
        return eventLoop.makeSucceededFuture("\(storageIdentifier)://\(info.platform)")
    }
    
    func getStoredFile(storedIn: StorageAccessUrl, into eventLoop: EventLoop) throws -> EventLoopFuture<StoredResult> {
        let resultUrl:URL!
        switch storedIn {
        case "\(storageIdentifier)://\(Platform.ios)":
            resultUrl = URL(string:TestingStorageService.defaultIpaUrl)!
        case "\(storageIdentifier)://\(Platform.android)":
            resultUrl = URL(string:TestingStorageService.defaultApkUrl)!
        default:
            throw  StorageError.notFound
        }
        return eventLoop.makeSucceededFuture(StoredResult.asUrI(url:resultUrl ))
    }
    
    func deleteStoredFileStorageId(storedIn: StorageAccessUrl, into eventLoop: EventLoop) throws -> EventLoopFuture<Void> {
        return eventLoop.makeSucceededFuture(())
    }
    
}
