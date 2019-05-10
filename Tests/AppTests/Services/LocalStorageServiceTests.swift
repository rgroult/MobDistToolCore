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
        do {
                try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)
            }
         catch { print("Unable to create \(baseURL) log directory.") }
        
        return baseURL.absoluteString
    }()
    
    override func setUp() {
        super.setUp()
        XCTAssertNoThrow(try storageService.initializeStore(with: ["RootDirectory":storeDirectory]))
        
    }
    
    func testInitStoreFile() throws {
        try? FileManager.default.removeItem(atPath: "/tmp/mdtOK")
        XCTAssertNoThrow(try storageService.initializeStore(with: ["RootDirectory":"/tmp/mdtOK"]))
        XCTAssertNoThrow(try storageService.initializeStore(with: ["RootDirectory":"/tmp/mdtOK"]))
        XCTAssertThrowsError(try storageService.initializeStore(with: ["RootDirectory":"/toto"]), "") { error in
            //print(error.localizedDescription)
            XCTAssertTrue(error.localizedDescription.contains("permission"))
        }
    }
    
    func testStoreFile() throws {
        let tempFile = createRandomFile(size: 1024)
        let info = StorageInfo(applicationName: "test", platform: .ios, version: "X.Y.Z", uploadFilename: nil, uploadContentType: nil)
        var accessUrl:StorageAccessUrl = ""
        XCTAssertNoThrow(accessUrl = try storageService.store(file: tempFile, with: info, into: app.eventLoop).wait())
        //reset to begin
        tempFile.seek(toFileOffset: 0)
        
        //retrieve storedFile
        let storedInfo = try storageService.getStoredFile(storedIn: accessUrl, into: app.eventLoop).wait()
        switch storedInfo {
        case .asFile(let file):
            //check file content
            let data = file.readDataToEndOfFile()
            XCTAssertEqual(tempFile.readDataToEndOfFile(), data)
            XCTAssertEqual(data.count, 1024)
        default:
            XCTAssertTrue(false)
        }
    }
    
    func testDeleteFile() throws {
        //store file
        let tempFile = createRandomFile(size: 1024)
        let info = StorageInfo(applicationName: "test", platform: .ios, version: "X.Y.Z", uploadFilename: nil, uploadContentType: nil)
        var accessUrl:StorageAccessUrl = ""
        XCTAssertNoThrow(accessUrl = try storageService.store(file: tempFile, with: info, into: app.eventLoop).wait())
        
        XCTAssertNoThrow(try storageService.deleteStoredFileStorageId(storedIn: accessUrl, into: app.eventLoop).wait())
        
        XCTAssertThrowsError(try storageService.deleteStoredFileStorageId(storedIn: accessUrl, into: app.eventLoop).wait(), "") { error in
            switch (error as? StorageError){
            case StorageError.notFound?:
                 XCTAssertTrue(true)
            default:
                 XCTAssertTrue(false)
            }
           // XCTAssertEqual((error as? StorageError.notFound) != nil)
        }
    }
    
    func testStoreBigFile() throws {
        let bigSize:UInt64 = 1024*1024*100 //100 M
        let tempFile = createRandomFile(size: Int(bigSize),randomData:false)
        
        let info = StorageInfo(applicationName: "test", platform: .ios, version: "X.Y.Z", uploadFilename: nil, uploadContentType: nil)
        var accessUrl:StorageAccessUrl = ""
        XCTAssertNoThrow(accessUrl = try storageService.store(file: tempFile, with: info, into: app.eventLoop).wait())
        
        //retrieve storedFile
        let storedInfo = try storageService.getStoredFile(storedIn: accessUrl, into: app.eventLoop).wait()
        switch storedInfo {
         case .asFile(let file):
            //check file size
            let endIdx = file.seekToEndOfFile()
            XCTAssertEqual(bigSize, endIdx)
            print("Size :\(bigSize)")
        default:
            XCTAssertTrue(false)
        }
    }
}

func createRandomFile(size:Int, randomData:Bool = true)->FileHandle {
    //let data = random(size).data(using: .utf8)
    let filename = "/tmp/test\(random(10))"
    XCTAssertTrue(FileManager.default.createFile(atPath:filename , contents:nil , attributes: nil))
    let file = FileHandle(forWritingAtPath: filename)
    var remaining = size
    let bufferSize = 1024*1014 // 1M
    while (remaining > 0) {
        let tmpSize = min(remaining,bufferSize)
        let data:Data
        if randomData {
            data = random(tmpSize).data(using: .utf8)!
        }else {
            data = Data(count: tmpSize)
        }
        file?.write(data)
        remaining = remaining - tmpSize
    }
    
    return FileHandle(forReadingAtPath: filename)!
}
