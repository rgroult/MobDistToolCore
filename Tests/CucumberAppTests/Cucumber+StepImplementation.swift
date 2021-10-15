//
//  File.swift
//  
//
//  Created by Remi Groult on 13/10/2021.
//

import Foundation
import CucumberSwift
import XCTest
import Vapor
import Meow
@testable import AppTests

struct StepContext {
    var app:Application!
    var context:Meow.MeowDatabase!
    func closeApp(){
        app.shutdown()
    }
    func eraseDatabase() throws {
        try context.raw.drop().wait()
    }
}
var currentStep:StepContext? = nil

extension Cucumber: StepImplementation {
    public var bundle: Bundle {
        class Findme { }
        let bundle = Bundle(for: Findme.self)
        //find test bundle
        if let bundleName = bundle.infoDictionary?["CFBundleName"] as? String, let bundleUrl = bundle.urls(forResourcesWithExtension: "bundle", subdirectory: nil)?.first(where: {$0.absoluteString.contains("\(bundleName).bundle")}) {
            //load bundle
            return Bundle(url: bundleUrl)!
        }
        return bundle
    }

    public func setupSteps() {
        print("setupSteps")
        
        BeforeScenario { (_) in
        }
        
        AfterScenario { _ in
            //close Server
            currentStep?.closeApp()
            currentStep = nil
        }
        
        //Global
        Given("^A started server$") { _, _ in
            print("Started Server")
            do {
                try startServer()
            }
            catch {
                XCTFail("Start server fail: \(error)")
            }
//            XCTAssertNoThrow (startServer)
            
        }
        
        setupStepsPermanentLinks()
    }
}

func startServer() throws {
    let app = try Application.runningAppTest()
    let context = app.meow
    currentStep = .init(app: app, context: context)
    try currentStep?.eraseDatabase()
}
