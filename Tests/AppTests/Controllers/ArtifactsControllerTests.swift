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

let ipaContentType = MediaType.parse(IPA_CONTENT_TYPE.data(using: .utf8)!)!
let apkContentType = MediaType.parse(APK_CONTENT_TYPE.data(using: .utf8)!)!

final class ArtifactsContollerTests: BaseAppTests {
    //MARK: - Tools
    class func uploadArtifactRequest(contentFile:Data,apiKey:String,branch:String?,version:String?,name:String,
                                     contentType:MediaType?,
                                     sortIdentifier:String? = nil,
                                     metaTags:[String:String]? = nil,
                                     inside app:Application ) throws ->Response {
        //POST '{apiKey}/{branch}/{version}/{artifactName}
        var uri = "/v2/Artifacts/\(apiKey)"
        if let branch = branch {
            uri =  uri + "/" + branch
        }
        if let version = version {
            uri =  uri + "/" + version
        }
        uri =  uri + "/" + name
        
        let beforeSend:(Request) throws -> () = { req in
            req.http.headers.add(name: "x-filename", value: "testArtifact.zip")
            req.http.headers.add(name: "x-mimetype", value: contentType?.description ?? "")
            req.http.contentType = .binary
            if let sortIdentifier = sortIdentifier {
                req.http.headers.add(name: "x-sortidentifier", value: sortIdentifier)
            }
            if let tags = metaTags,let tagsAsData = try? JSONEncoder().encode(tags) {
                
                req.http.headers.add(name: "x-metaTags", value: String(data: tagsAsData,encoding: .utf8)!)
            }
        }
        
        let body = contentFile.convertToHTTPBody()
        return try app.clientSyncTest(.POST, uri,body,beforeSend:beforeSend)
        // XCTAssertEqual(resp.http.status.code , 200)
    }
    
    class func uploadArtifactError(contentFile:Data,apiKey:String,branch:String?,version:String?,name:String, contentType:MediaType?,inside app:Application ) throws ->ErrorDto {
        let resp = try uploadArtifactRequest(contentFile: contentFile, apiKey: apiKey, branch: branch, version: version, name: name, contentType:contentType, inside: app)
        XCTAssertEqual(resp.http.status.code , 400)
        return try resp.content.decode(ErrorDto.self).wait()
    }
    
    class func uploadArtifactSuccess(contentFile:Data,apiKey:String,branch:String?,version:String?,name:String, contentType:MediaType?,
                                     sortIdentifier:String? = nil,
                                     metaTags:[String:String]? = nil,
                                     inside app:Application ) throws ->ArtifactDto {
        let resp = try uploadArtifactRequest(contentFile: contentFile, apiKey: apiKey, branch: branch, version: version, name: name, contentType:contentType, sortIdentifier: sortIdentifier, metaTags: metaTags, inside: app)
        XCTAssertEqual(resp.http.status.code , 200)
        let result = try resp.content.decode(ArtifactDto.self).wait()
        if let _ = branch, let _ = version {
            XCTAssertEqual(result.branch , branch)
            XCTAssertEqual(result.version , version)
        }else {
            //latest version
            XCTAssertEqual(result.version , "latest")
            XCTAssertEqual(result.branch , "")
        }
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
    private var androidApiKey:String?
    private var token:String?

    override func setUp() {
        super.setUp()
        //register user
        _ = try? register(registerInfo: userIOS, inside: app)
        //login
        token = try? login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
        do {
            iOSApiKey = try ApplicationsControllerTests.createApp(with: appDtoiOS, inside: app,token: token).apiKey
            androidApiKey = try ApplicationsControllerTests.createApp(with: appDtoAndroid, inside: app,token: token).apiKey
        }catch{
            print("Error \(error)")
        }
        
    }
    func testCreateWithApiKey() throws {
        //print("Api Key \(iOSApiKey)")
        XCTAssertNotNil(iOSApiKey)
    }
    
    func testCreateIpaArtifact() throws{
        XCTAssertNotNil(iOSApiKey)
        
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let artifact = try type(of:self).uploadArtifactSuccess(contentFile: fileData, apiKey: iOSApiKey!, branch: "master", version: "1.2.3", name: "prod", contentType:ipaContentType, inside: app)
        let metadata = artifact.metaDataTags
        XCTAssertEqual(metadata?["CFBundleShortVersionString"],"1.0")
        XCTAssertEqual(metadata?["CFBundleIdentifier"],"com.petri.calculator.calculator")
        XCTAssertEqual(artifact.sortIdentifier,artifact.version)
    }
    
    func testCreateApkArtifact() throws{
        XCTAssertNotNil(androidApiKey)
        
        let fileData = try type(of:self).fileData(name: "testdroid-sample-app", ext: "apk")
        let artifact = try type(of:self).uploadArtifactSuccess(contentFile: fileData, apiKey: androidApiKey!, branch: "master", version: "1.2.3", name: "prod", contentType:apkContentType, inside: app)
        let metadata = artifact.metaDataTags
        // TODO check metadata
        XCTAssertEqual(metadata?["PACKAGE_NAME"],"com.testdroid.sample.android")
        XCTAssertEqual(metadata?["MIN_SDK"],"14")
        XCTAssertEqual(metadata?["VERSION_CODE"],"1")
        XCTAssertEqual(metadata?["VERSION_NAME"],"0.3")
        XCTAssertEqual(metadata?["TARGET_SDK"],"19")
        XCTAssertEqual(artifact.sortIdentifier,artifact.version)
    }
    
    
    func testCreateIpaArtifactFullArgs() throws{
        XCTAssertNotNil(iOSApiKey)
        
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let artifact = try type(of:self).uploadArtifactSuccess(contentFile: fileData, apiKey: iOSApiKey!, branch: "master", version: "1.2.3", name: "prod", contentType:ipaContentType, sortIdentifier: "Fake",metaTags: ["Hello":"World"], inside: app)
        let metadata = artifact.metaDataTags
        XCTAssertEqual(metadata?["CFBundleShortVersionString"],"1.0")
        XCTAssertEqual(metadata?["CFBundleIdentifier"],"com.petri.calculator.calculator")
        XCTAssertEqual(metadata?["Hello"],"World")
        XCTAssertEqual(artifact.sortIdentifier,"Fake")
    }
    
    func testCreateApkArtifactFullArgs() throws{
        XCTAssertNotNil(androidApiKey)
        
        let fileData = try type(of:self).fileData(name: "testdroid-sample-app", ext: "apk")
        let artifact = try type(of:self).uploadArtifactSuccess(contentFile: fileData, apiKey: androidApiKey!, branch: "master", version: "1.2.3", name: "prod", contentType:apkContentType, sortIdentifier: "Fake",metaTags: ["Hello":"World"], inside: app)
        let metadata = artifact.metaDataTags
        XCTAssertEqual(metadata?["PACKAGE_NAME"],"com.testdroid.sample.android")
        XCTAssertEqual(metadata?["MIN_SDK"],"14")
        XCTAssertEqual(metadata?["VERSION_CODE"],"1")
        XCTAssertEqual(metadata?["VERSION_NAME"],"0.3")
        XCTAssertEqual(metadata?["TARGET_SDK"],"19")
        XCTAssertEqual(metadata?["Hello"],"World")
        XCTAssertEqual(artifact.sortIdentifier,"Fake")
    }
    
    func testCreateIpaArtifactWithSortIdentifier() throws{
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
        let error = try type(of:self).uploadArtifactError(contentFile: fileData, apiKey: iOSApiKey!, branch: "master", version: "1.2.3", name: "prod", contentType:ipaContentType,inside: app)
         XCTAssertEqual(error.reason,"ArtifactError.invalidContent")
    }
    
    func testCreateArtifactBadApiKey() throws{
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let error = try type(of:self).uploadArtifactError(contentFile: fileData, apiKey:"badApiKey", branch: "master", version: "1.2.3", name: "prod", contentType:ipaContentType, inside: app)
        XCTAssertEqual(error.reason,"ApplicationError.notFound")
    }
    
    func testCreateSameArtifact() throws{
        try testCreateIpaArtifact()
        
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
        try testCreateIpaArtifact()
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
    
    func testCreateLastArtifact() throws{
        XCTAssertNotNil(iOSApiKey)
        
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let artifact = try type(of:self).uploadArtifactSuccess(contentFile: fileData, apiKey: iOSApiKey!, branch: nil, version: "latest", name: "prod", contentType:ipaContentType, inside: app)
        let metadata = artifact.metaDataTags
        XCTAssertEqual(metadata?["CFBundleShortVersionString"],"1.0")
        XCTAssertEqual(metadata?["CFBundleIdentifier"],"com.petri.calculator.calculator")
        XCTAssertEqual(artifact.sortIdentifier,nil)
    }
    
    func testCreateLastArtifactFullArgs() throws{
        XCTAssertNotNil(iOSApiKey)
        
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let artifact = try type(of:self).uploadArtifactSuccess(contentFile: fileData, apiKey: iOSApiKey!, branch:nil, version: "latest", name: "prod", contentType:ipaContentType, sortIdentifier: "Fake",metaTags: ["Hello":"World"], inside: app)
        let metadata = artifact.metaDataTags
        XCTAssertEqual(metadata?["CFBundleShortVersionString"],"1.0")
        XCTAssertEqual(metadata?["CFBundleIdentifier"],"com.petri.calculator.calculator")
        XCTAssertEqual(metadata?["Hello"],"World")
        XCTAssertEqual(artifact.sortIdentifier,nil)
    }
    
    func testDownloadInfo() throws {
        XCTAssertNotNil(iOSApiKey)
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let dwInfo = try donwloadInfo(apiKey: iOSApiKey!, fileData: fileData)
        print(dwInfo)
    }
    
    func donwloadInfo(apiKey:String, fileData:Data,contentType:MediaType = ipaContentType) throws -> DownloadInfoDto{
    let artifact = try type(of:self).uploadArtifactSuccess(contentFile: fileData, apiKey: apiKey, branch: "master", version: "1.2.3", name: "prod", contentType:contentType, inside: app)
    
    //retrieve download info
    let uri = "/v2/Artifacts/\(artifact.uuid)/download"
    
    let response = try app.clientSyncTest(.GET, uri,token:token)
    return try response.content.decode(DownloadInfoDto.self).wait()
    }
    
    func testDownloadiOSManifest() throws {
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let dwInfo = try donwloadInfo(apiKey: iOSApiKey!, fileData: fileData)
        
        let manifestPlist = try app.clientSyncTest(.GET, dwInfo.installUrl,isAbsoluteUrl:true)
        XCTAssertEqual(manifestPlist.http.contentType, .xml)
        //download url must be in manifest
        XCTAssertTrue("\(manifestPlist.content)".contains(dwInfo.directLinkUrl))
        print(manifestPlist.content)
    }
    
    func testDownloadiOSDownloadFile() throws {
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let dwInfo = try donwloadInfo(apiKey: iOSApiKey!, fileData: fileData)
        print(dwInfo.directLinkUrl)
        let ipaFile = try app.clientSyncTest(.GET, dwInfo.directLinkUrl,isAbsoluteUrl:true)
        XCTAssertTrue(ipaFile.http.contentType == .binary)
        XCTAssertEqual(ipaFile.http.body.count,fileData.count)
        //print(ipaFile.http.headers)
      //  print(ipaFile.content)
    }
    
    func testDownloadAndroidDownloadFile() throws {
        let fileData = try type(of:self).fileData(name: "testdroid-sample-app", ext: "apk")
        let dwInfo = try donwloadInfo(apiKey: androidApiKey!, fileData: fileData,contentType:apkContentType)
        print(dwInfo.directLinkUrl)
        let ipaFile = try app.clientSyncTest(.GET, dwInfo.directLinkUrl,isAbsoluteUrl:true)
        XCTAssertTrue(ipaFile.http.contentType == .binary)
        XCTAssertEqual(ipaFile.http.body.count,fileData.count)
        //print(ipaFile.http.headers)
        //  print(ipaFile.content)
    }
    
    class func fileData(name:String,ext:String) throws -> Data {
        let dirConfig = DirectoryConfig.detect()
       let filePath = dirConfig.workDir+"Ressources/\(name).\(ext)"
      //  let filePath =  Bundle.init(for: ArtifactsContollerTests.self).url(forResource: name, withExtension: ext)
        return try Data(contentsOf: URL(fileURLWithPath: filePath))
    }
}
