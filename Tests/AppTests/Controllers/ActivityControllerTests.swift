//
//  File.swift
//  
//
//  Created by Remi Groult on 19/05/2022.
//

import Foundation
import Vapor
import XCTest
@testable import App

final class ActivityControllerTests: BaseAppTests {
    
    private func loginAdAdmin() throws -> String {
        var environment = app.environment
        let configuration = try MdtConfiguration.loadConfig(from: nil, from: &environment)
        let loginResp = try login(withEmail: configuration.initialAdminEmail, password: configuration.initialAdminPassword, inside: app)
        return loginResp.token
    }
    
    func testSummary() throws {
       
        let token = try loginAdAdmin()
        
        let summaryblock = {(app:Application) -> MetricsSummaryDto in
            var httpResult = try app.clientSyncTest(.GET, "/v2/Monitoring/summary", nil , token: token)
            XCTAssertEqual(httpResult.http.status.code , 200)
            let summary = try httpResult.content.decode(MetricsSummaryDto.self).wait()
            
            return summary
        }
        
        let initialSummary = try summaryblock(app)
        XCTAssertEqual(initialSummary.ApplicationsCount , 0)
        XCTAssertEqual(initialSummary.ArtifactsCount , 0)
        XCTAssertEqual(initialSummary.UsersCount , 1)
        
        //add Apps
        try ApplicationsControllerTests.populateApplications(nbre: 10, inside: app, token: token)
        let populatedAppSummary = try summaryblock(app)
        XCTAssertEqual(populatedAppSummary.ApplicationsCount , 10)
        XCTAssertEqual(populatedAppSummary.ArtifactsCount , 0)
        XCTAssertEqual(populatedAppSummary.UsersCount , 1)
        
        //add User
        try register(registerInfo: userANDROID, inside: app)
        
        //upload artifact
        let iOSApiKey = try ApplicationsControllerTests.createApp(with: appDtoiOS, inside: app,token: token).apiKey
        let fileData = try ArtifactsContollerTests.fileData(name: "calculator", ext: "ipa")
        let artifact = try ArtifactsContollerTests.uploadArtifactSuccess(contentFile: fileData, apiKey: iOSApiKey!, branch: "master", version: "1.2.3", name: "prod", contentType:ipaContentType, inside: app)
        
        let appSummary = try summaryblock(app)
        XCTAssertEqual(appSummary.ApplicationsCount , 11)
        XCTAssertEqual(appSummary.ArtifactsCount , 1)
        XCTAssertEqual(appSummary.UsersCount , 2)
    }
    
    func testLogs() throws {
        let token = try loginAdAdmin()
        
        let requestBlock = {(app:Application) -> MessageDto in
            var httpResult = try app.clientSyncTest(.GET, "/v2/Monitoring/logs", ["lines":"300"] , token: token)
            XCTAssertEqual(httpResult.http.status.code , 200)
            let result = try httpResult.content.decode(MessageDto.self).wait()
            return result
        }
        
        let logs = try requestBlock(app)
        let initialSize = logs.message.count
        
        try register(registerInfo: userANDROID, inside: app)
        let logsAfterRegister = try requestBlock(app)
        XCTAssertTrue(logsAfterRegister.message.count > logs.message.count)
    }
}
