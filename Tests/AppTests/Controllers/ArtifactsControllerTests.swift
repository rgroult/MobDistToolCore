//
//  ArtifactsControllerTests.swift
//  AppTests
//
//  Created by Remi Groult on 03/05/2019.
//

import Foundation
import Vapor
import XCTest
@testable import App

//Samples App found here :https://github.com/bitbar/bitbar-samples/
//Thank to him

let ipaContentType = MediaType.parse(IPA_CONTENT_TYPE.data(using: .utf8)!)
let apkContentType = MediaType.parse(APK_CONTENT_TYPE.data(using: .utf8)!)

final class ArtifactsContollerTests: BaseAppTests {
    //MARK: - Tools
    class func uploadArtifactRequest(contentFile:Data,apiKey:String,branch:String,version:String,name:String,
                                     contentType:MediaType?,
                                     sortIdentifier:String? = nil,
                                     metaTags:[String:String]? = nil,
                                     inside app:Application ) throws ->Response {
        //POST '{apiKey}/{branch}/{version}/{artifactName}
        let uri = "/v2/Artifacts/\(apiKey)/\(branch)/\(version)/\(name)"
        let beforeSend:(Request) throws -> () = { req in
            req.http.headers.add(name: "X_MDT_filename", value: "test.ipa")
            req.http.headers.add(name: "x-mimetype", value: contentType?.description ?? "")
            req.http.contentType = .binary
            if let sortIdentifier = sortIdentifier {
                req.http.headers.add(name: "X_MDT_sortIdentifier", value: sortIdentifier)
            }
            if let tags = metaTags,let tagsAsData = try? JSONEncoder().encode(tags) {
                
                req.http.headers.add(name: "X_MDT_metaTags", value: String(data: tagsAsData,encoding: .utf8)!)
            }
        }
        
        let body = contentFile.convertToHTTPBody()
        return try app.clientSyncTest(.POST, uri,body,beforeSend:beforeSend)
        // XCTAssertEqual(resp.http.status.code , 200)
    }
    
    class func uploadArtifactError(contentFile:Data,apiKey:String,branch:String,version:String,name:String, contentType:MediaType?,inside app:Application ) throws ->ErrorDto {
        let resp = try uploadArtifactRequest(contentFile: contentFile, apiKey: apiKey, branch: branch, version: version, name: name, contentType:contentType, inside: app)
        XCTAssertEqual(resp.http.status.code , 400)
        return try resp.content.decode(ErrorDto.self).wait()
    }
    
    class func uploadArtifactSuccess(contentFile:Data,apiKey:String,branch:String,version:String,name:String, contentType:MediaType?,
                                     sortIdentifier:String? = nil,
                                     metaTags:[String:String]? = nil,
                                     inside app:Application ) throws ->ArtifactDto {
        let resp = try uploadArtifactRequest(contentFile: contentFile, apiKey: apiKey, branch: branch, version: version, name: name, contentType:contentType, sortIdentifier: sortIdentifier, metaTags: metaTags, inside: app)
        XCTAssertEqual(resp.http.status.code , 200)
        let result = try resp.content.decode(ArtifactDto.self).wait()
        XCTAssertEqual(result.branch , branch)
        XCTAssertEqual(result.version , version)
        XCTAssertEqual(result.name , name)
        XCTAssertNotNil(result.contentType)
        XCTAssertEqual(result.size,contentFile.count)
        return result
    }
    
    class func deleteArtifact(apiKey:String,branch:String,version:String,name:String, inside app:Application ) throws -> Response {
        let uri = "/v2/Artifacts/\(apiKey)/\(branch)/\(version)/\(name)"
        
        return try app.clientSyncTest(.DELETE, uri)
    }
    
    class func deleteArtifactSucess(apiKey:String,branch:String,version:String,name:String, inside app:Application ) throws -> MessageDto {
        let uri = "/v2/Artifacts/\(apiKey)/\(branch)/\(version)/\(name)"
        
        let resp = try app.clientSyncTest(.DELETE, uri)
         XCTAssertEqual(resp.http.status.code , 200)
        let message = try resp.content.decode(MessageDto.self).wait()
         XCTAssertEqual(message.message , "Artifact Deleted")
         return message
    }
    
    class func deleteArtifactError(apiKey:String,branch:String,version:String,name:String, inside app:Application ) throws -> ErrorDto {
        let resp = try deleteArtifact(apiKey: apiKey, branch: branch, version: version, name: name, inside: app)
        XCTAssertEqual(resp.http.status.code , 400)
        return try resp.content.decode(ErrorDto.self).wait()
    }
    
    //MARK: - Tests
    private var iOSApiKey:String?
    private var token:String?

    override func setUp() {
        super.setUp()
        //register user
        _ = try? register(registerInfo: userIOS, inside: app)
        //login
        token = try? login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
        do {
            iOSApiKey = try ApplicationsTests.createApp(with: appDtoiOS, inside: app,token: token).apiKey
        }catch{
            print("Error \(error)")
        }
        
    }
    func testCreateWithApiKey() throws {
        //print("Api Key \(iOSApiKey)")
        XCTAssertNotNil(iOSApiKey)
    }
    
    func testCreateArtifact() throws{
        XCTAssertNotNil(iOSApiKey)
        
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let artifact = try type(of:self).uploadArtifactSuccess(contentFile: fileData, apiKey: iOSApiKey!, branch: "master", version: "1.2.3", name: "prod", contentType:ipaContentType, inside: app)
        let metadata = artifact.metaDataTags
        XCTAssertEqual(metadata?["CFBundleShortVersionString"],"1.0")
        XCTAssertEqual(metadata?["CFBundleIdentifier"],"com.petri.calculator.calculator")
        XCTAssertEqual(artifact.sortIdentifier,artifact.version)
    }
    
    func testCreateArtifactFullArgs() throws{
        XCTAssertNotNil(iOSApiKey)
        
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let artifact = try type(of:self).uploadArtifactSuccess(contentFile: fileData, apiKey: iOSApiKey!, branch: "master", version: "1.2.3", name: "prod", contentType:ipaContentType, sortIdentifier: "Fake",metaTags: ["Hello":"World"], inside: app)
        let metadata = artifact.metaDataTags
        XCTAssertEqual(metadata?["CFBundleShortVersionString"],"1.0")
        XCTAssertEqual(metadata?["CFBundleIdentifier"],"com.petri.calculator.calculator")
        XCTAssertEqual(metadata?["Hello"],"World")
        XCTAssertEqual(artifact.sortIdentifier,"Fake")
    }
    
    func testCreateArtifactWithSortIdentifier() throws{
        XCTAssertNotNil(iOSApiKey)
        
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let artifact = try type(of:self).uploadArtifactSuccess(contentFile: fileData, apiKey: iOSApiKey!, branch: "master", version: "1.2.3", name: "prod", contentType:ipaContentType, inside: app)
        let metadata = artifact.metaDataTags
        XCTAssertEqual(metadata?["CFBundleShortVersionString"],"1.0")
        XCTAssertEqual(metadata?["CFBundleIdentifier"],"com.petri.calculator.calculator")
        XCTAssertEqual(artifact.sortIdentifier,artifact.version)
    }
    
    func testCreateArtifactBigFile() throws{
        let bigSize:UInt64 = 1024*1024*300 //300 M
        let tempFile = createRandomFile(size: Int(bigSize),randomData:false)
        
        let fileData = tempFile.readDataToEndOfFile()
        try type(of:self).uploadArtifactSuccess(contentFile: fileData, apiKey: iOSApiKey!, branch: "master", version: "1.2.3", name: "prod", contentType:ipaContentType,inside: app)
    }
    
    func testCreateArtifactBadApiKey() throws{
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let error = try type(of:self).uploadArtifactError(contentFile: fileData, apiKey:"badApiKey", branch: "master", version: "1.2.3", name: "prod", contentType:ipaContentType, inside: app)
        XCTAssertEqual(error.reason,"ApplicationError.notFound")
    }
    
    func testCreateSameArtifact() throws{
        try testCreateArtifact()
        
        let errorResp = try type(of: self).uploadArtifactError(contentFile: try type(of:self).fileData(name: "calculator", ext: "ipa"), apiKey: iOSApiKey!, branch: "master", version: "1.2.3", name: "prod", contentType: ipaContentType, inside: app)
        XCTAssertEqual(errorResp.reason , "ArtifactError.alreadyExist")
    }
    
    func testBadContentType() throws{
        
        let errorResp = try type(of: self).uploadArtifactError(contentFile: try type(of:self).fileData(name: "calculator", ext: "ipa"), apiKey: iOSApiKey!, branch: "master", version: "1.2.3", name: "prod", contentType: .jpeg, inside: app)
        XCTAssertEqual(errorResp.reason , "ArtifactError.invalidContentType")
    }
    
    func testBadContentType2() throws{
        
        let errorResp = try type(of: self).uploadArtifactError(contentFile: try type(of:self).fileData(name: "calculator", ext: "ipa"), apiKey: iOSApiKey!, branch: "master", version: "1.2.3", name: "prod", contentType:apkContentType, inside: app)
        XCTAssertEqual(errorResp.reason , "ArtifactError.invalidContentType")
    }
    
    func testDeleteArtifact() throws {
        try testCreateArtifact()
        let resp = try type(of:self).deleteArtifactSucess(apiKey: iOSApiKey!, branch: "master", version: "1.2.3", name: "prod", inside: app)
    }
    
    func testDeleteArtifactTwice() throws {
        try testDeleteArtifact()
        
        let error = try type(of:self).deleteArtifactError(apiKey: iOSApiKey!, branch: "master", version: "1.2.3", name: "prod", inside: app)
        XCTAssertEqual(error.reason , "ArtifactError.notFound")
    }
    
    func testDeleteArtifactNotFound() throws {
        try testDeleteArtifact()
        let error = try type(of:self).deleteArtifactError(apiKey: iOSApiKey!, branch: "master", version: "1.2.3", name: "TOTOPROD", inside: app)
        XCTAssertEqual(error.reason , "ArtifactError.notFound")
    }
    
    func testDeleteArtifactBasApiKey() throws {
        try testDeleteArtifact()
        let error = try type(of:self).deleteArtifactError(apiKey: "BadApiKey", branch: "master", version: "1.2.3", name: "prod", inside: app)
        XCTAssertEqual(error.reason , "ApplicationError.notFound")
    }
    
    class func fileData(name:String,ext:String) throws -> Data {
        let dirConfig = DirectoryConfig.detect()
       let filePath = dirConfig.workDir+"Ressources/\(name).\(ext)"
      //  let filePath =  Bundle.init(for: ArtifactsContollerTests.self).url(forResource: name, withExtension: ext)
        return try Data(contentsOf: URL(fileURLWithPath: filePath))
    }
}
