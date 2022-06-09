//
//  ArtifactsControllerTests.swift
//  AppTests
//
//  Created by Remi Groult on 03/05/2019.
//

import Foundation
import Vapor
import XCTest
import XCTVapor
@testable import App

//Samples App found here :https://github.com/bitbar/bitbar-samples/
//Thank to him

let ipaContentType = HTTPMediaType(type: "application", subType: "octet-stream ipa") //HTTPMediaType.parse(IPA_CONTENT_TYPE.data(using: .utf8)!)!
let apkContentType = HTTPMediaType.fileExtension("apk")! //HTTPMediaType.parse(APK_CONTENT_TYPE.data(using: .utf8)!)!

final class ArtifactsContollerTests: BaseAppTests {
    //MARK: - Tools
    class func uploadArtifactRequest(contentFile:Data,apiKey:String,branch:String?,version:String?,name:String,
                                     contentType:HTTPMediaType?,
                                     sortIdentifier:String? = nil,
                                     metaTags:[String:String]? = nil,
                                     inside app:Application ) throws -> ResponseType {
        //POST '{apiKey}/{branch}/{version}/{artifactName}
        var uri = "/v2/Artifacts/\(apiKey)"
        if let branch = branch {
            uri =  uri + "/" + branch
        }
        if let version = version {
            uri =  uri + "/" + version
        }
        uri =  uri + "/" + name
        
        let beforeSend:(inout RequestType) throws -> () = { req in
            req.headers.add(name: "x-filename", value: "testArtifact.zip")
            req.headers.add(name: "x-mimetype", value: contentType?.description ?? "")
            req.headers.contentType = .binary
            if let sortIdentifier = sortIdentifier {
                req.headers.add(name: "x-sortidentifier", value: sortIdentifier)
            }
            if let tags = metaTags,let tagsAsData = try? JSONEncoder().encode(tags) {
                
                req.headers.add(name: "x-metaTags", value: String(data: tagsAsData,encoding: .utf8)!)
            }
        }
        
       // let body = contentFile.convertToHTTPBody()
        return try app.clientSyncTest(.POST, uri){req in
            req.body = .init(data: contentFile)
            //try req.content.encode(contentFile, as: .binary)
           // req.body.writeData(contentFile)
            try beforeSend(&req)
        }
        // XCTAssertEqual(resp.http.status.code , 200)
    }
    
    class func uploadArtifactError(contentFile:Data,apiKey:String,branch:String?,version:String?,name:String, contentType:HTTPMediaType?,inside app:Application ) throws ->ErrorDto {
        let resp = try uploadArtifactRequest(contentFile: contentFile, apiKey: apiKey, branch: branch, version: version, name: name, contentType:contentType, inside: app)
        XCTAssertEqual(resp.http.status.code , 400)
        return try resp.content.decode(ErrorDto.self).wait()
    }
    
    class func uploadArtifactSuccess(contentFile:Data,apiKey:String,branch:String?,version:String?,name:String, contentType:HTTPMediaType?,
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
    
    class func deleteArtifact(apiKey:String,branch:String,version:String,name:String, inside app:Application ) throws -> ResponseType {
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

    func testCreateIpaArtifactWithEmptySortIdentifier() throws{
        XCTAssertNotNil(iOSApiKey)

        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let artifact = try type(of:self).uploadArtifactSuccess(contentFile: fileData, apiKey: iOSApiKey!, branch: "master", version: "1.2.3", name: "prod", contentType:ipaContentType,sortIdentifier: "", inside: app)
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
    
    func testDownloadInfoIOS() throws {
        XCTAssertNotNil(iOSApiKey)
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let dwInfo = try donwloadInfo(apiKey: iOSApiKey!, fileData: fileData)
        //test all Urls
        try [dwInfo.directLinkUrl,dwInfo.installPageUrl].map{
            let resp = try app.clientSyncTest(.GET, $0,isAbsoluteUrl:true)
            #if os(Linux)
                //URLSEssion on linux doens not handle redirect by default
            XCTAssertTrue( [.seeOther,.ok].contains(resp.http.status))
            #else
            XCTAssertEqual(resp.http.status,.ok)
            #endif
        }
        print(dwInfo)
    }
    
    func testDownloadInfoAndroid() throws {
        XCTAssertNotNil(androidApiKey)
        let fileData = try type(of:self).fileData(name: "testdroid-sample-app", ext: "apk")
        let dwInfo = try donwloadInfo(apiKey: androidApiKey!, fileData: fileData,contentType:apkContentType)
        //test all Urls
        try [dwInfo.directLinkUrl,dwInfo.installPageUrl,dwInfo.installUrl].map{
            let resp = try app.clientSyncTest(.GET, $0,isAbsoluteUrl:true)
            //print(resp.content)
            #if os(Linux)
                //URLSEssion on linux doens not handle redirect by default
            XCTAssertTrue( [.seeOther,.ok].contains(resp.http.status))
            #else
            XCTAssertEqual(resp.http.status,.ok)
            #endif
        }
        print(dwInfo)
    }
    
    func donwloadInfo(apiKey:String, fileData:Data,contentType:HTTPMediaType = ipaContentType) throws -> DownloadInfoDto{
        return try type(of:self).donwloadInfo(apiKey: apiKey, fileData: fileData, contentType: contentType, into: app,with: token)
    }
    class func donwloadInfo(apiKey:String, fileData:Data,contentType:HTTPMediaType = ipaContentType, into app:Application,with token:String?) throws -> DownloadInfoDto{
    let artifact = try ArtifactsContollerTests.uploadArtifactSuccess(contentFile: fileData, apiKey: apiKey, branch: "master", version: "1.2.3", name: "prod", contentType:contentType, inside: app)
    
    //retrieve download info
    let uri = "/v2/Artifacts/\(artifact.uuid)/download"
    
    let response = try app.clientSyncTest(.GET, uri,token:token)
    return try response.content.decode(DownloadInfoDto.self).wait()
    }
    
    func testDownloadiOSManifest() throws {
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let dwInfo = try donwloadInfo(apiKey: iOSApiKey!, fileData: fileData)
        
        var plistUrl = dwInfo.installUrl.replacingOccurrences(of: "itms-services://?action=download-manifest&url=", with: "")
        plistUrl = plistUrl.removingPercentEncoding!
        
        var manifestPlist = try app.clientSyncTest(.GET, plistUrl,isAbsoluteUrl:true)
        XCTAssertEqual(manifestPlist.content.contentType, .xml)
        //download url must be in manifest
        let  data = manifestPlist.bodyData
        //if let data =  manifestPlist.body.readData(length: manifestPlist.body.readableBytes) {
            let manifestPlistDict =  try PropertyListSerialization.propertyList(from: data, format: nil) as! [String:Any]
            let metadata = (((manifestPlistDict["items"] as? Array<Any>)?.first as? [String:Any])?["metadata"]) as? [String:Any]
            let assets = ((((manifestPlistDict["items"] as? Array<Any>)?.first as? [String:Any])?["assets"]) as? [Any])?.first as? [String:Any]
            let kind = ((((manifestPlistDict["items"] as? Array<Any>)?.first as? [String:Any])?["assets"]) as? [Any])?[1] as? [String:Any]
            XCTAssertEqual(metadata?["title"] as? String, appDtoiOS.name)
            XCTAssertEqual(metadata?["bundle-version"] as? String, "1")
            XCTAssertEqual(metadata?["bundle-identifier"] as? String, "com.petri.calculator.calculator")
            
            XCTAssertEqual(assets?["url"] as? String, dwInfo.directLinkUrl)
            let iconUrl = kind?["url"] as? String
            XCTAssertNotNil(iconUrl)
            //test icon
            let iconFile = try app.clientSyncTest(.GET, iconUrl! ,isAbsoluteUrl:true)
            XCTAssertEqual(iconFile.http.status, .ok)
      //  }
    }
    
    func testDownloadiOSDownloadFile() throws {
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let dwInfo = try donwloadInfo(apiKey: iOSApiKey!, fileData: fileData)
        print(dwInfo.directLinkUrl)
        let ipaFile = try app.clientSyncTest(.GET, dwInfo.directLinkUrl,isAbsoluteUrl:true)
        XCTAssertTrue(ipaFile.content.contentType == .binary)
        XCTAssertEqual(ipaFile.bodyCount,fileData.count)
        XCTAssertEqual( ipaFile.headers.first(name: .contentLength),"\(fileData.count)")
        
        //print(ipaFile.http.headers)
      //  print(ipaFile.content)
    }
/*
    func testDownloadFile() throws {
        let ipaFile = try app.clientSyncTest(.GET, "<File URL>" ,isAbsoluteUrl:true)
        print( ipaFile.http.headers)
    }*/
    
    func testDownloadAndroidDownloadFile() throws {
        let fileData = try type(of:self).fileData(name: "testdroid-sample-app", ext: "apk")
        let dwInfo = try donwloadInfo(apiKey: androidApiKey!, fileData: fileData,contentType:apkContentType)
        print(dwInfo.directLinkUrl)
        XCTAssertEqual(dwInfo.installUrl,dwInfo.directLinkUrl)
        let apkFile = try app.clientSyncTest(.GET, dwInfo.installUrl,isAbsoluteUrl:true)
        XCTAssertTrue(apkFile.content.contentType == .binary)
        XCTAssertEqual(apkFile.bodyCount,fileData.count)
        XCTAssertEqual( apkFile.headers.first(name: .contentLength),"\(fileData.count)")
       
        //print(ipaFile.http.headers)
        //  print(ipaFile.content)
    }
    
    func testInstallPageIOS() throws {
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let dwInfo = try donwloadInfo(apiKey: iOSApiKey!, fileData: fileData)
        var installPage = try app.clientSyncTest(.GET, dwInfo.installPageUrl ,isAbsoluteUrl:true)
        //check install page contains installUrl
        let data = installPage.bodyData
        if /*let data =  installPage.body.readData(length: installPage.body.readableBytes), */let stringContent = String(data: data, encoding: .utf8) {
            XCTAssertTrue(stringContent.contains(dwInfo.installUrl))
        }else {
            XCTAssertTrue(false)
        }
       // print(installPage)
    }

    func testInstallPageAndroid() throws {
        let fileData = try type(of:self).fileData(name: "testdroid-sample-app", ext: "apk")
        let dwInfo = try donwloadInfo(apiKey: androidApiKey!, fileData: fileData,contentType:apkContentType)
        var installPage = try app.clientSyncTest(.GET, dwInfo.installPageUrl ,isAbsoluteUrl:true)
        //check install page contains installUrl
        let data = installPage.bodyData
        if /*let data =  installPage.body.readData(length: installPage.body.readableBytes),*/ let stringContent = String(data: data, encoding: .utf8) {
            XCTAssertTrue(stringContent.contains(dwInfo.installUrl))
        }else {
            XCTAssertTrue(false)
        }

    }
    
    class func fileData(name:String,ext:String) throws -> Data {
        let dirConfig = DirectoryConfiguration.detect()
       let filePath = dirConfig.workingDirectory+"Ressources/\(name).\(ext)"
      //  let filePath =  Bundle.init(for: ArtifactsContollerTests.self).url(forResource: name, withExtension: ext)
        return try Data(contentsOf:  URL(fileURLWithPath: filePath))
    }
}

final class LocalStorageArtifactsContollerTests: BaseAppTests {
    private var iOSApiKey:String?
    private var androidApiKey:String?
    private var token:String?
    
    override func setUp() {
        var env = Environment.xcode
        env.arguments += ["-DstorageMode=FilesLocalStorage"]
        configure(with: env)
        
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

    func testStorageDeleteArtifactData() throws {
        let fileData = try ArtifactsContollerTests.fileData(name: "calculator", ext: "ipa")
        let version = "XX.XX.XX"
        let _ = try ArtifactsContollerTests.uploadArtifactSuccess(contentFile: fileData, apiKey: iOSApiKey!, branch: "master", version: version, name: "prod", contentType:ipaContentType, inside: app!)
        //check storage dir
        let mdtConfig = try app.appConfiguration()// try app.make(MdtConfiguration.self)
        let storagePath:String = "\(mdtConfig.storageConfiguration!["RootDirectory"]!)/ios/\(appDtoiOS.name)/\(version)" //!
        var files = try FileManager.default.contentsOfDirectory(atPath:storagePath)
        XCTAssertEqual(files.count, 1)
        //delete artifact
        _ = try ArtifactsContollerTests.deleteArtifactSucess(apiKey: iOSApiKey!, branch: "master", version: version, name: "prod", inside: app)
        files = try FileManager.default.contentsOfDirectory(atPath:storagePath)
        XCTAssertEqual(files.count,0)
        print(files)
    }
    
    func testStorageDownloadiOSManifest() throws {
        let fileData = try ArtifactsContollerTests.fileData(name: "calculator", ext: "ipa")
        let dwInfo = try ArtifactsContollerTests.donwloadInfo(apiKey: iOSApiKey!, fileData: fileData,into:app!,with:token)
        
        var plistUrl = dwInfo.installUrl.replacingOccurrences(of: "itms-services://?action=download-manifest&url=", with: "")
        plistUrl = plistUrl.removingPercentEncoding!
        
        var manifestPlist = try app.clientSyncTest(.GET, plistUrl,isAbsoluteUrl:true)
        XCTAssertEqual(manifestPlist.content.contentType, .xml)
        //download url must be in manifest
         let data = manifestPlist.bodyData //  manifestPlist.body.readData(length: manifestPlist.body.readableBytes) {
            let manifestPlistDict =  try PropertyListSerialization.propertyList(from: data, format: nil) as! [String:Any]
            let metadata = (((manifestPlistDict["items"] as? Array<Any>)?.first as? [String:Any])?["metadata"]) as? [String:Any]
            let assets = ((((manifestPlistDict["items"] as? Array<Any>)?.first as? [String:Any])?["assets"]) as? [Any])?.first as? [String:Any]
            XCTAssertEqual(metadata?["title"] as? String, appDtoiOS.name)
            XCTAssertEqual(metadata?["bundle-version"] as? String, "1")
            XCTAssertEqual(metadata?["bundle-identifier"] as? String, "com.petri.calculator.calculator")
            
            XCTAssertEqual(assets?["url"] as? String, dwInfo.directLinkUrl)
      //  }
        
        let ipaFile = try app.clientSyncTest(.GET, dwInfo.directLinkUrl,isAbsoluteUrl:true)
    
        XCTAssertTrue(ipaFile.content.contentType == ipaContentType)
        XCTAssertEqual(ipaFile.http.bodyCount,fileData.count)
    }

    func testStorageDownloadiOSDownloadFile() throws {
            let fileData = try ArtifactsContollerTests.fileData(name: "calculator", ext: "ipa")
            let dwInfo = try ArtifactsContollerTests.donwloadInfo(apiKey: iOSApiKey!, fileData: fileData,into:app!,with:token)
            print(dwInfo.directLinkUrl)
            let file = try app.clientSyncTest(.GET, dwInfo.directLinkUrl,isAbsoluteUrl:true)

            XCTAssertTrue(file.content.contentType == ipaContentType)
            XCTAssertEqual(file.headers.first(name: .contentLength),"\(fileData.count)")
            XCTAssertEqual(file.bodyCount,fileData.count)

        }
    
    func testStoragePartialDownloadiOSDownloadFile() throws {
            let fileData = try ArtifactsContollerTests.fileData(name: "calculator", ext: "ipa")
            let dwInfo = try ArtifactsContollerTests.donwloadInfo(apiKey: iOSApiKey!, fileData: fileData,into:app!,with:token)
            print(dwInfo.directLinkUrl)
        
            let partialSize = 1024
            let file = try app.clientSyncTest(.GET, dwInfo.directLinkUrl,isAbsoluteUrl:true){ request in
                request.headers.add(name: "Range", value: "bytes=0-\(partialSize - 1)")
                print("Request \(request)")
            }
            print(file.headers)
            XCTAssertTrue(file.status == .partialContent)
            XCTAssertTrue(file.content.contentType == ipaContentType)
            XCTAssertEqual( file.headers.first(name: .contentLength),"\(partialSize)")
            XCTAssertEqual(file.bodyCount,partialSize)
        }


        func testStorageDownloadAndroidDownloadFile() throws {
            let fileData = try ArtifactsContollerTests.fileData(name: "testdroid-sample-app", ext: "apk")
            let dwInfo = try ArtifactsContollerTests.donwloadInfo(apiKey: androidApiKey!, fileData: fileData,contentType:apkContentType,into:app!,with:token)
            print(dwInfo.directLinkUrl)
            XCTAssertEqual(dwInfo.installUrl,dwInfo.directLinkUrl)
            let file = try app.clientSyncTest(.GET, dwInfo.installUrl,isAbsoluteUrl:true)

            XCTAssertTrue(file.content.contentType == apkContentType)
            XCTAssertEqual( file.headers.first(name: .contentLength),"\(fileData.count)")
            XCTAssertEqual(file.bodyCount,fileData.count)
        }
    
    func testStoragePartialDownloadAndroidDownloadFile() throws {
        let fileData = try ArtifactsContollerTests.fileData(name: "testdroid-sample-app", ext: "apk")
        let dwInfo = try ArtifactsContollerTests.donwloadInfo(apiKey: androidApiKey!, fileData: fileData,contentType:apkContentType,into:app!,with:token)
        print(dwInfo.directLinkUrl)
        XCTAssertEqual(dwInfo.installUrl,dwInfo.directLinkUrl)
        let partialSize = 1024
        let file = try app.clientSyncTest(.GET, dwInfo.installUrl,isAbsoluteUrl:true){ request in
            request.headers.add(name: "Range", value: "bytes=0-\(partialSize - 1)")
            print("Request \(request)")
        }
        print(file.headers)
        XCTAssertTrue(file.status == .partialContent)
        XCTAssertTrue(file.content.contentType == apkContentType)
        XCTAssertEqual( file.headers.first(name: .contentLength),"\(partialSize)")
        XCTAssertEqual(file.bodyCount,partialSize)
    }
}
