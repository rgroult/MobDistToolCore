//
//  DeployScriptTests.swift
//  AppTests
//
//  Created by Rémi Groult on 25/11/2019.
//

import Foundation
import Vapor
import XCTest
import Pagination
@testable import App

final class DeployScriptTests: BaseAppTests {
    //MARK: - Tests
    private var iOSApiKey:String!
    private var androidApiKey:String!
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
    
    func callScript(apiKey:String, args:[String]){
        //call http://localhost:8080/great/v2/Artifacts/92f5cb62-610b-4a4c-9777-b2f0b4b1171e/deploy | | python -
        
        let curlTask = Process()
        curlTask.launchPath = "/usr/bin/curl"
        curlTask.arguments = ["-Ls","http://localhost:8081/v2/Artifacts/\(apiKey)/deploy"]
        let pipe = Pipe()
        curlTask.standardOutput = pipe
        
        let pythonTask = Process()
        pythonTask.launchPath = "/usr/bin/python"
        pythonTask.standardInput = pipe
        pythonTask.arguments = ["-"] + args
        let outputPipe = Pipe()
        pythonTask.standardOutput = outputPipe
        
        do {
            #if os(Linux)
            try curlTask.run()
            try pythonTask.run()
            #else
            curlTask.launch()
            pythonTask.launch()
            #endif
            
            curlTask.waitUntilExit()
            pythonTask.waitUntilExit()
            let status = pythonTask.terminationStatus
            
            print("Deploy result : \(String( data: outputPipe.fileHandleForReading.readDataToEndOfFile(),encoding:.utf8))")
            XCTAssertEqual(status, 0)
            
           //  let plistBinary = outputPipe.fileHandleForReading.readDataToEndOfFile()
           //  var plistFormat = PropertyListSerialization.PropertyListFormat.binary
        }catch {
            XCTAssertNil(error)
        }
    }
    
    func getIpaAbsoluteFilePath() -> String {
        let dirConfig = DirectoryConfig.detect()
        let filePath = dirConfig.workDir+"Ressources/calculator.ipa"
        return filePath
    }
    
    func testCallOK(){
        callScript(apiKey: iOSApiKey, args: ["ADD","--latest","fullParameters","-name", "test1", "-file" ,getIpaAbsoluteFilePath()])
        callScript(apiKey: iOSApiKey, args: ["DELETE","--latest","fullParameters","-name", "test1"])
    }
}
