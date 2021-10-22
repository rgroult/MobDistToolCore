//
//  File.swift
//
//
//  Created by Remi Groult on 15/10/2021.
//

@testable import App
import CucumberSwift
import Foundation
import TestsToolkit
import XCTest

public extension Cucumber {
    func setupStepsPermanentLinks() {
        When("^I create a permanent link for last version on branch master$") { _, _ in
            do {
            let appDto = (currentStep?.testContext["APP"] as? ApplicationDto)
            let linkDto = try createPermanentLink(appUUID: appDto!.uuid, branch: "master", name: "prod", validity: 1, inside: currentStep!.app, token: currentStep?.loginToken)
            print("DTO \(linkDto)")
            } catch {
                XCTFail("Error : \(error)")
            }
        }/*
        Then("^Then I can see 1 permanent link on application detail$") { _, _ in
            do {
                let appDto = (currentStep?.testContext["APP"] as? ApplicationDto)
                let appDetail = try applicationDetail(appUUID: appDto!.uuid, inside: currentStep!.app, token: currentStep?.loginToken)

                XCTAssertTrue(appDetail.permanentLinks?.count == 1)
            }catch {
                XCTFail("Error : \(error)")
            }
        }*/
        Given("^Create a sample iOS Application$") { _, _ in
            do {
                let app = try createApp(with: appDtoiOS, inside: currentStep!.app, token: currentStep?.loginToken)
                currentStep?.testContext["APP"] = app
            } catch {
                XCTFail("Error : \(error)")
            }
        }
        Given("^Create a user and login$") { _, _ in
            do {
                let userDto = try register(registerInfo: userIOS, inside: currentStep!.app)
                let loginToken = try login(withEmail: userIOS.email, password: userIOS.password, inside: currentStep!.app).token
                currentStep?.loginToken = loginToken
            } catch {
                XCTFail("Error : \(error)")
            }
        }
        Given("^Upload Samples Artifacts and branch master$") { _, _ in
            do {
                let fileData = try fileData(name: "calculator", ext: "ipa")
                let apiKey = (currentStep?.testContext["APP"] as? ApplicationDto)?.apiKey
                for i in 0 ... 10 {
                    let version = "1.0.\(i)"
                    try uploadArtifactSuccess(contentFile: fileData, apiKey: apiKey!, branch: "master", version: version, name: "prod", contentType: ipaContentType, inside: currentStep!.app)
                }
            } catch {
                XCTFail("Error : \(error)")
            }
        }
        
        Given("^Upload sample artifact named \"(.*?)\", version \"(.*?)\" on branch \"(.*?)\"$") { matches, _ in
            let artifactName = matches[1]
            let version = matches[2]
            let branch = matches[3]
            do {
                let fileData = try fileData(name: "calculator", ext: "ipa")
                let apiKey = (currentStep?.testContext["APP"] as? ApplicationDto)?.apiKey
                try uploadArtifactSuccess(contentFile: fileData, apiKey: apiKey!, branch: branch, version: version, name: artifactName, contentType: ipaContentType, inside: currentStep!.app)
                
            }catch {
                XCTFail("Error : \(error)")
            }
            
        }

        
        
        When("^I get iOS Applation detail$") { _, _ in
            do {
                let appDto = (currentStep?.testContext["APP"] as? ApplicationDto)
                let appDetail = try applicationDetail(appUUID: appDto!.uuid, inside: currentStep!.app, token: currentStep?.loginToken)
                currentStep?.testContext["APP"] = appDetail
                print("new detail \(currentStep?.testContext["APP"])")
            }catch {
                XCTFail("Error : \(error)")
            }
        }
        
        Then("^I can see (\\d+) permanent link on iOS Application application detail$") { matches, _ in
            let integer = Int(matches[1])
            
            let appDto = (currentStep?.testContext["APP"] as? ApplicationDto)
            XCTAssertEqual(appDto?.permanentLinks?.count, integer)
        }
        
        Then("^I can't see any available version in first permanent link$") { _, _ in
            let appDto = (currentStep?.testContext["APP"] as? ApplicationDto)
            XCTAssertNotNil(appDto)
            XCTAssertNil(appDto?.permanentLinks?.first?.currentVersion)
        }
        
        Then("^I can see a available version \"(.*?)\" in first permanent link$") { matches, _ in
            let version = matches[1]
            let appDto = (currentStep?.testContext["APP"] as? ApplicationDto)
            XCTAssertNotNil(appDto)
            XCTAssertEqual(appDto?.permanentLinks?.first?.currentVersion,version)
        }
        
        Then("^I can see a available version in first permanent link$") { _, _ in
            let appDto = (currentStep?.testContext["APP"] as? ApplicationDto)
            XCTAssertNotNil(appDto?.permanentLinks?.first?.currentVersion)
        }
        Then("^I can donwload artifact from first permanent link installUrl$") { _, _ in
            let appDto = (currentStep?.testContext["APP"] as? ApplicationDto)
            let installPageUrl = appDto?.permanentLinks?.first?.installUrl
            XCTAssertNotNil(installPageUrl)
            XCTAssertNoThrow {
                let resp = try currentStep!.app.clientSyncTest(.GET, installPageUrl!,isAbsoluteUrl:true)
                #if os(Linux)
                //URLSEssion on linux doens not handle redirect by default
                    XCTAssertTrue( [.seeOther,.ok].contains(resp.http.status))
                #else
                    XCTAssertEqual(resp.http.status,.ok)
                #endif
            }
            /*
             var installPage = try app.clientSyncTest(.GET, dwInfo.installPageUrl ,isAbsoluteUrl:true)
             //check install page contains installUrl
             let data = installPage.bodyData
             if /*let data =  installPage.body.readData(length: installPage.body.readableBytes), */let stringContent = String(data: data, encoding: .utf8) {
                 XCTAssertTrue(stringContent.contains(dwInfo.installUrl))
             }else {
                 XCTAssertTrue(false)
             }
             */
            
        }

        
    }
}


