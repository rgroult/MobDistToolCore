//
//  File.swift
//
//
//  Created by gogetta on 02/11/2021.
//

@testable import App
import CucumberSwift
import Foundation
import TestsToolkit
import XCTest

public extension Cucumber {
    func setupStepsApplications() {
        When("^I delete sample iOS Application$") { _, _ in
            let currentApp = currentStep?.testContext["APP"] as? ApplicationDto
            XCTAssertNotNil(currentApp)
            XCTAssertEqual(currentApp?.name, appDtoiOS.name)
            XCTAssertEqual(currentApp?.platform, appDtoiOS.platform)
            do {
                try deleteApp(appUUID: currentApp!.uuid, inside: currentStep!.app, token: currentStep!.loginToken)
            } catch {
                XCTFail("Error : \(error)")
            }
        }
        Then("^I retrieve all applications, I can see (\\d+) application\\(s\\)$") { matches, _ in
            let integer = Int(matches[1])
            do {
                let page:Paginated<ApplicationSummaryDto> = try paginationRequest(path: "/v2/Applications", perPage: 99999, app: currentStep!.app, order: .descending,sortBy:"created" , pageNumber: 0, maxElt: 99999, token: currentStep?.loginToken)
                XCTAssertEqual(page.data.count, integer)
            } catch {
                XCTFail("Error : \(error)")
            }
        }
       
        Then("^I create a permanent link for last version on branch \"(.*?)\"$") { matches, _ in
            let branch = matches[1]
            do {
            let appDto = (currentStep?.testContext["APP"] as? ApplicationDto)
            let linkDto = try createPermanentLink(appUUID: appDto!.uuid, branch: branch, name: "prod", validity: 1, inside: currentStep!.app, token: currentStep?.loginToken)
            print("DTO \(linkDto)")
            } catch {
                XCTFail("Error : \(error)")
            }
        }
       
        Given("^Upload (\\d+) artifact\\(s\\) named \"(.*?)\", from prefix version \"(.*?)\" on branch \"(.*?)\"$") { matches, _ in
            let artifactsCount = Int(matches[1])
            let artifactName = matches[2]
            let versionPrefix = matches[3]
            let branch = matches[4]
            do {
                let fileData = try fileData(name: "calculator", ext: "ipa")
                let apiKey = (currentStep?.testContext["APP"] as? ApplicationDto)?.apiKey
                
                for number in 0..<artifactsCount! {
                    try uploadArtifactSuccess(contentFile: fileData, apiKey: apiKey!, branch: branch, version: "\(versionPrefix)_\(number)", name: artifactName, contentType: ipaContentType, inside: currentStep!.app)
                }
            } catch {
                XCTFail("Error : \(error)")
            }
        }
        
        Then("^I retrieve all artifacts for current applications, I can see (\\d+) artifact\\(s\\)$") { matches, _ in
            let integer = Int(matches[1])
            do {
                let uuid = (currentStep?.testContext["APP"] as? ApplicationDto)?.uuid
                let page:Paginated<ArtifactDto> = try paginationRequest(path: "/v2/Applications/\(uuid!)/versions", perPage: 99999, app: currentStep!.app, order: .descending,sortBy:"created" , pageNumber: 0, maxElt: 99999, token: currentStep?.loginToken)
                XCTAssertEqual(page.data.count, integer)
            } catch {
                XCTFail("Error : \(error)")
            }
        }
        Then("^I count artifacts in database, I can see (\\d+) artifact\\(s\\)$") { matches, _ in
            let integer = Int(matches[1])
            XCTAssertEqual(try! currentStep!.context.collection(for: Artifact.self).count(where: []).wait(),integer)
        }
        Then("^I count tokens in database, I can see (\\d+) token\\(s\\)$") { matches, _ in
            let integer = Int(matches[1])
            XCTAssertEqual(try! currentStep!.context.collection(for: TokenInfo.self).count(where: []).wait(),integer)
        }
    }
}
