//
//  LocalStorageServiceTests.swift
//  AppTests
//
//  Created by Remi Groult on 28/02/2019.
//

import Foundation
import XCTest
@testable import App



final class LocalStorageServiceTests: BaseAppTests {
    let storageService = LocalStorageService()
    
    lazy var storeDirectory: String = {
        var baseURL = URL(fileURLWithPath: "/tmp/MDT\(random(5))")
        
        /// Append executable name; ~/Library/Caches/executableName/ (macOS),
        /// or /var/log/executableName/ (Linux)
        do {
                try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)
            }
         catch { print("Unable to create \(baseURL) log directory.") }
        
        return baseURL.absoluteString
    }()
    
    override func setUp() {
        super.setUp()
        XCTAssertNoThrow(try storageService.initializeStore(with: ["RootDirectory":storeDirectory], into: app.eventLoop).wait())
        
    }
    
    func testInitStoreFile() throws {
        try? FileManager.default.removeItem(atPath: "/tmp/mdtOK")
        XCTAssertNoThrow(try storageService.initializeStore(with: ["RootDirectory":"/tmp/mdtOK"], into: app.eventLoop).wait())
        XCTAssertNoThrow(try storageService.initializeStore(with: ["RootDirectory":"/tmp/mdtOK"], into: app.eventLoop).wait())
        XCTAssertThrowsError(try storageService.initializeStore(with: ["RootDirectory":"/toto"], into: app.eventLoop).wait(), "") { error in
            //print(error.localizedDescription)
            XCTAssertTrue(error.localizedDescription.contains("permission"))
        }
    }
    
    func testStoreFile() throws {
        let tempFile = createRandomFile(size: 1024)
        let info = StorageInfo(applicationName: "test", platform: .ios, version: "X.Y.Z", uploadFilename: nil, uploadContentType: nil)
        var accessUrl:StorageAccessUrl = ""
        XCTAssertNoThrow(accessUrl = try storageService.store(file: tempFile, with: info, into: app.eventLoop).wait())
        
        //retrieve storedFile
        let storedInfo = try storageService.getStoredFile(storedIn: accessUrl, into: app.eventLoop).wait()
        switch storedInfo {
        case .asFile(let file):
            //check file content
            XCTAssertEqual(file.readDataToEndOfFile(), tempFile.readDataToEndOfFile())
        default:
            XCTAssertTrue(false)
        }
        
    }
    
    func createRandomFile(size:Int)->FileHandle {
        let data = random(size).data(using: .utf8)
        let filename = "/tmp/test\(random(10))"
        XCTAssertTrue(FileManager.default.createFile(atPath:filename , contents:data , attributes: nil))
        return FileHandle(forReadingAtPath: filename)!
    }
}
