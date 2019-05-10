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
        //POST 'in/artifacts/{apiKey}/{branch}/{version}/{artifactName}
        let uri = "/v2/Artifacts/\(iOSApiKey!)/master/1.2.3/prod"
        let beforeSend:(Request) throws -> () = { req in
            req.http.headers.add(name: "X_MDT_filename", value: "test.ipa")
            req.http.contentType = ipaContentType
           // req.http.headers.add(name: "content-type", value: IPA_CONTENT_TYPE)
        }
        
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let body = fileData.convertToHTTPBody()
        
        let resp = try app.clientSyncTest(.POST, uri,body, token:token,beforeSend:beforeSend)
        print(resp.content)
        XCTAssertEqual(resp.http.status.code , 200)
    }
    
    func testCreateArtifactBigFile() throws{
        let uri = "/v2/Artifacts/\(iOSApiKey!)/master/1.2.X/prod"
        let beforeSend:(Request) throws -> () = { req in
            req.http.headers.add(name: "X_MDT_filename", value: "BigFile")
            req.http.contentType = ipaContentType
            // req.http.headers.add(name: "content-type", value: IPA_CONTENT_TYPE)
        }
        let bigSize:UInt64 = 1024*1024*300 //300 M
        let tempFile = createRandomFile(size: Int(bigSize),randomData:false)
        
        let fileData = tempFile.readDataToEndOfFile()
        let body = fileData.convertToHTTPBody()
        
        let resp = try app.clientSyncTest(.POST, uri,body, token:token,beforeSend:beforeSend)
        print(resp.content)
        XCTAssertEqual(resp.http.status.code , 200)
    }
    
    func testCreateSameArtifact() throws{
        try testCreateArtifact()
        
        let uri = "/v2/Artifacts/\(iOSApiKey!)/master/1.2.3/prod"
        let beforeSend:(Request) throws -> () = { req in
            req.http.headers.add(name: "X_MDT_filename", value: "test.ipa")
            req.http.contentType = ipaContentType
            // req.http.headers.add(name: "content-type", value: IPA_CONTENT_TYPE)
        }
        
        let fileData = try type(of:self).fileData(name: "calculator", ext: "ipa")
        let body = fileData.convertToHTTPBody()
        
        let resp = try app.clientSyncTest(.POST, uri,body, token:token,beforeSend:beforeSend)
        print(resp.content)
        XCTAssertEqual(resp.http.status.code , 400)
        let errorResp = try resp.content.decode(ErrorDto.self).wait()
        XCTAssertEqual(errorResp.reason , "ArtifactError.alreadyExist")
    }
    
    func testDeleteArtifact() throws {
        try testCreateArtifact()
        let uri = "/v2/Artifacts/\(iOSApiKey!)/master/1.2.3/prod"
        let beforeSend:(Request) throws -> () = { req in
            req.http.headers.add(name: "X_MDT_filename", value: "test.ipa")
            req.http.contentType = ipaContentType
            // req.http.headers.add(name: "content-type", value: IPA_CONTENT_TYPE)
        }
        let resp = try app.clientSyncTest(.DELETE, uri, token:token,beforeSend:beforeSend)
        print(resp.content)
    }
    
    
    class func fileData(name:String,ext:String) throws -> Data {
        let filePath =  Bundle.init(for: ArtifactsContollerTests.self).url(forResource: name, withExtension: ext)
        return try Data(contentsOf: filePath!)
    }
}
