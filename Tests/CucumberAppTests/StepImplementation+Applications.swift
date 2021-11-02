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
        }
        Then("^I retrieve all applications, I can see (\\d+) application\\(s\\)$") { matches, _ in
            let integer = matches[1]
        }
       
        Then("^I create a permanent link for last version on branch master$") { _, _ in
        }
       
        Given("^Upload (\\d+) artifact\\(s\\) named \"(.*?)\", from prefix version \"(.*?)\" on branch \"(.*?)\"$") { matches, _ in
            let string = matches[1]
            let stringTwo = matches[2]
            let stringThree = matches[3]
            let integer = matches[1]
        }
        Then("^I retrieve all artifacts for current applications, I can see (\\d+) artifact\\(s\\)$") { matches, _ in
            let integer = matches[1]
        }
        Then("^I count artifacts in database, I can see (\\d+) artifact\\(s\\)$") { matches, _ in
            let integer = matches[1]
        }
        Then("^I count tokens in database, I can see (\\d+) token\\(s\\)$") { matches, _ in
            let integer = matches[1]
        }
    }
}
