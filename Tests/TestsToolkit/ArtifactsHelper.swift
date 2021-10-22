//
//  File.swift
//  
//
//  Created by Remi Groult on 18/10/2021.
//

import Foundation
import Vapor
import XCTest
@testable import App

public func uploadArtifactRequest(contentFile:Data,apiKey:String,branch:String?,version:String?,name:String,
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


public func uploadArtifactSuccess(contentFile:Data,apiKey:String,branch:String?,version:String?,name:String, contentType:HTTPMediaType?,
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


public func fileData(name:String,ext:String) throws -> Data {
    let dirConfig = DirectoryConfiguration.detect()
   let filePath = dirConfig.workingDirectory+"Ressources/\(name).\(ext)"
  //  let filePath =  Bundle.init(for: ArtifactsContollerTests.self).url(forResource: name, withExtension: ext)
    return try Data(contentsOf:  URL(fileURLWithPath: filePath))
}
